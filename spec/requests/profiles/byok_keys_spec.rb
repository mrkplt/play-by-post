require "rails_helper"

RSpec.describe Profiles::ByokKeysController, type: :request do
  let(:user) { create(:user, :with_profile) }
  let(:value_type) { "openrouter_key" }

  describe "POST /profile/byok_key" do
    it "generates an EncryptedValue for the current user (job runs inline in test)", :ai_credential, db: true do
      sign_in(user)

      expect {
        post profile_byok_key_path
      }.to change(EncryptedValue, :count).by(1)

      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_present
      expect(response).to redirect_to(profile_path)
    end

    it "is idempotent — does not create a second EncryptedValue if one already exists", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      expect {
        post profile_byok_key_path
      }.not_to change(EncryptedValue, :count)
    end

    it "flashes a ready notice when the EncryptedValue already exists", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      post profile_byok_key_path

      expect(flash[:notice]).to eq("Your encryption key is ready.")
    end

    it "flashes a preparing notice when the EncryptedValue does not exist yet, even if another owner has one", :ai_credential, db: true do
      # The default test queue_adapter is :inline (config/environments/test.rb),
      # so KeypairGenerationJob would otherwise run synchronously inside the
      # request and the EncryptedValue would already exist by the time the
      # notice is computed — swap to :test here to observe the real "still
      # enqueued, not yet generated" state the async worker leaves in
      # production. Another owner's EncryptedValue also exists, so the notice
      # must be scoped to current_user specifically, not "does any
      # EncryptedValue exist at all."
      create(:encrypted_value, owner: create(:user), value_type: value_type)
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      sign_in(user)

      post profile_byok_key_path

      expect(flash[:notice]).to eq("Preparing your encryption key…")
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "redirects unauthenticated users", :db do
      post profile_byok_key_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /profile/byok_key" do
    let(:fixture_path) { Rails.root.join("spec/fixtures/crypto_keypairs") }
    let(:envelope) { JSON.parse(File.read(fixture_path.join("webcrypto_blob.json"))) }

    it "stores the sealed envelope and marks the key present", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }

      encrypted_value.reload
      expect(encrypted_value.sealed_blob).to be_present
      expect(user.reload.ai_key_present?).to be(true)
    end

    it "flashes an exact success notice", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }

      expect(flash[:notice]).to eq("OpenRouter key saved.")
    end

    it "stores exactly the submitted envelope fields, not an arbitrary hash", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }

      blob = T.must(encrypted_value.reload.sealed_blob)
      expect(blob.wrapped_key).to eq(envelope.fetch("wrapped_key"))
      expect(blob.iv).to eq(envelope.fetch("iv"))
      expect(blob.ciphertext).to eq(envelope.fetch("ciphertext"))
    end

    it "the stored envelope decrypts back to the original plaintext via CryptoService", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }

      private_key_pem = File.read(fixture_path.join("private_key.pem"))
      plaintext = Crypto::CryptoService.new(private_key_pem).decrypt(T.must(encrypted_value.reload.sealed_blob))
      expect(plaintext).to eq(File.read(fixture_path.join("webcrypto_plaintext.txt")).strip)
    end

    it "replaces an existing sealed key rather than erroring", :ai_credential, db: true do
      encrypted_value = create(
        :encrypted_value, owner: user, value_type: value_type,
        sealed_value: { wrapped_key: "old", iv: "old", ciphertext: "old" }.to_json
      )
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }

      expect(encrypted_value.reload.sealed_blob&.wrapped_key).to eq(envelope.fetch("wrapped_key"))
    end

    it "redirects with an alert when no EncryptedValue exists yet", :db do
      sign_in(user)
      patch profile_byok_key_path, params: { byok_key: envelope }

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("No keypair")
    end

    it "flashes an exact alert on a malformed envelope, without touching the stored key", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type, sealed_value: nil)
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: { wrapped_key: "only-this" } }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("Could not save that key.")
      expect(encrypted_value.reload.sealed_value).to be_nil
    end

    it "redirects unauthenticated users", :db do
      patch profile_byok_key_path, params: { byok_key: envelope }
      expect(response).to have_http_status(:redirect)
    end
  end
end
