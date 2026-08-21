require "rails_helper"

RSpec.describe Profiles::AiKeypairsController, type: :request do
  let(:user) { create(:user, :with_profile) }

  describe "POST /profile/ai_keypair" do
    it "generates a keypair for the current user (job runs inline in test)", :ai_credential, db: true do
      sign_in(user)

      expect {
        post profile_ai_keypair_path
      }.to change(AiKeypair, :count).by(1)

      expect(AiKeypair.find_by(owner: user)).to be_present
      expect(response).to redirect_to(profile_path)
    end

    it "is idempotent — does not create a second keypair if one already exists", :ai_credential, db: true do
      create(:ai_keypair, owner: user)
      sign_in(user)

      expect {
        post profile_ai_keypair_path
      }.not_to change(AiKeypair, :count)
    end

    it "flashes a ready notice when the keypair already exists", :ai_credential, db: true do
      create(:ai_keypair, owner: user)
      sign_in(user)

      post profile_ai_keypair_path

      expect(flash[:notice]).to eq("Your encryption key is ready.")
    end

    it "flashes a preparing notice when the keypair does not exist yet, even if another owner has one", :ai_credential, db: true do
      # The default test queue_adapter is :inline (config/environments/test.rb),
      # so AiKeypairGenerationJob would otherwise run synchronously inside the
      # request and the keypair would already exist by the time the notice is
      # computed — swap to :test here to observe the real "still enqueued,
      # not yet generated" state the async worker leaves in production.
      # Another owner's keypair also exists, so the notice must be scoped to
      # current_user specifically, not "does any AiKeypair exist at all."
      create(:ai_keypair, owner: create(:user))
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      sign_in(user)

      post profile_ai_keypair_path

      expect(flash[:notice]).to eq("Preparing your encryption key…")
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "redirects unauthenticated users", :db do
      post profile_ai_keypair_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /profile/ai_keypair" do
    let(:fixture_path) { Rails.root.join("spec/fixtures/ai_keypairs") }
    let(:envelope) { JSON.parse(File.read(fixture_path.join("webcrypto_blob.json"))) }

    it "stores the sealed envelope and marks the key present", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      keypair.reload
      expect(keypair.sealed_blob).to be_present
      expect(user.reload.ai_key_present?).to be(true)
    end

    it "sets ai_key_reference to the keypair's own fingerprint", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      expect(user.reload.ai_key_reference).to eq(keypair.fingerprint)
    end

    it "flashes an exact success notice", :ai_credential, db: true do
      create(:ai_keypair, owner: user, public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      expect(flash[:notice]).to eq("OpenRouter key saved.")
    end

    it "stores exactly the submitted envelope fields, not an arbitrary hash", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      blob = T.must(keypair.reload.sealed_blob)
      expect(blob.wrapped_key).to eq(envelope.fetch("wrapped_key"))
      expect(blob.iv).to eq(envelope.fetch("iv"))
      expect(blob.ciphertext).to eq(envelope.fetch("ciphertext"))
    end

    it "the stored envelope decrypts back to the original plaintext via CryptoService", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      private_key_pem = File.read(fixture_path.join("private_key.pem"))
      plaintext = AiKeypairs::CryptoService.new(private_key_pem).decrypt(T.must(keypair.reload.sealed_blob))
      expect(plaintext).to eq(File.read(fixture_path.join("webcrypto_plaintext.txt")).strip)
    end

    it "replaces an existing sealed key rather than erroring", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, sealed_key: { wrapped_key: "old", iv: "old", ciphertext: "old" }.to_json)
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      expect(keypair.reload.sealed_blob&.wrapped_key).to eq(envelope.fetch("wrapped_key"))
    end

    it "redirects with an alert when no keypair exists yet", :db do
      sign_in(user)
      patch profile_ai_keypair_path, params: { ai_keypair: envelope }

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("No keypair")
    end

    it "flashes an exact alert on a malformed envelope, without touching the stored key", :ai_credential, db: true do
      keypair = create(:ai_keypair, owner: user, sealed_key: nil)
      sign_in(user)

      patch profile_ai_keypair_path, params: { ai_keypair: { wrapped_key: "only-this" } }

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to eq("Could not save that key.")
      expect(keypair.reload.sealed_key).to be_nil
    end

    it "redirects unauthenticated users", :db do
      patch profile_ai_keypair_path, params: { ai_keypair: envelope }
      expect(response).to have_http_status(:redirect)
    end
  end
end
