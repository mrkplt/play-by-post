require "rails_helper"

# The whole BYOK lifecycle responds in place: show is the pending poll's
# target, and create/update/destroy answer with Turbo Streams swapping the
# control frame (and, where key presence changes, the game-controls section) — no
# action redirects. Flash rides flash.now into the toast stream, so outcome
# copy is asserted on the response body, never on a persisted flash.
RSpec.describe Profiles::ByokKeysController, type: :request do
  let(:user) { create(:user, :with_profile) }
  let(:value_type) { "openrouter_key" }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:frame_id) { Ui::ByokKeyFormComponent::FRAME_ID }

  describe "GET /profile/byok_key" do
    it "renders the pending spinner with the frame poll while no keypair exists", :db do
      sign_in(user)

      get profile_byok_key_path

      expect(response.body).to include(frame_id)
      expect(response.body).to include("frame-poll")
      expect(response.body).to include("Preparing your encryption key…")
    end

    it "renders the paste-and-seal form once the keypair exists", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      get profile_byok_key_path

      expect(response.body).to include("byok-key-seal")
      expect(response.body).not_to include("frame-poll")
    end

    it "renders the key-present state once a key is sealed", :ai_credential, db: true do
      create(:encrypted_value, :sealed, owner: user, value_type: value_type)
      sign_in(user)

      get profile_byok_key_path

      expect(response.body).to include("Delete key")
      expect(response.body).not_to include("byok-key-seal")
    end

    it "redirects unauthenticated users", :db do
      get profile_byok_key_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /profile/byok_key" do
    it "generates an EncryptedValue for the current user (job runs inline in test)", :ai_credential, db: true do
      sign_in(user)

      expect {
        post profile_byok_key_path, headers: turbo_headers
      }.to change(EncryptedValue, :count).by(1)

      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_present
    end

    it "is idempotent — does not create a second EncryptedValue if one already exists", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      expect {
        post profile_byok_key_path, headers: turbo_headers
      }.not_to change(EncryptedValue, :count)
    end

    it "streams the settled paste form with a ready toast when the EncryptedValue already exists — nothing to wait on", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      post profile_byok_key_path, headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("byok-key-seal")
      expect(response.body).to include("Your encryption key is ready.")
    end

    context "when the keypair does not exist yet (the real async case)" do
      # The default test queue_adapter is :inline (config/environments/test.rb),
      # so KeypairGenerationJob would otherwise run synchronously inside the
      # request and the EncryptedValue would already exist by the time the
      # response is computed — swap to :test here to observe the real "still
      # enqueued, not yet generated" state the async worker leaves in
      # production.
      around do |example|
        original_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test
        example.run
      ensure
        ActiveJob::Base.queue_adapter = original_adapter
      end

      it "responds with a Turbo Stream that swaps in the polling pending spinner, not a redirect", :db do
        sign_in(user)

        post profile_byok_key_path, headers: turbo_headers

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include(frame_id)
        expect(response.body).to include("frame-poll")
        expect(response.body).to include("Preparing your encryption key…")
      end

      it "does not persist the preparing notice into the next full page load", :db do
        sign_in(user)

        post profile_byok_key_path, headers: turbo_headers

        # flash.now, so it is consumed by this render and gone on the next request.
        get profile_path
        expect(response.body).not_to include("Preparing your encryption key…")
      end
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

      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      encrypted_value.reload
      expect(encrypted_value.sealed_blob).to be_present
      expect(user.reload.ai_key_present?).to be(true)
    end

    it "streams the key-present control, the game-controls section, and an exact success toast", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Delete key")
      expect(response.body).to include("game_controls")
      expect(response.body).to include("OpenRouter key saved.")
    end

    it "stores exactly the submitted envelope fields, not an arbitrary hash", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      blob = T.must(encrypted_value.reload.sealed_blob)
      expect(blob.wrapped_key).to eq(envelope.fetch("wrapped_key"))
      expect(blob.iv).to eq(envelope.fetch("iv"))
      expect(blob.ciphertext).to eq(envelope.fetch("ciphertext"))
    end

    it "the stored envelope decrypts back to the original plaintext via CryptoService", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type)
      encrypted_value.public_key.update!(public_key: File.read(fixture_path.join("public_key.pem")))
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      private_key_pem = File.read(fixture_path.join("private_key.pem"))
      plaintext = Crypto::CryptoService.new(private_key_pem).decrypt(T.must(encrypted_value.reload.sealed_blob))
      expect(plaintext).to eq(File.read(fixture_path.join("webcrypto_plaintext.txt")).strip)
    end

    it "refuses to seal over an already-sealed key — delete is the only way to change it", :ai_credential, db: true do
      encrypted_value = create(
        :encrypted_value, owner: user, value_type: value_type,
        sealed_value: { wrapped_key: "old", iv: "old", ciphertext: "old" }.to_json
      )
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      expect(response.body).to include("A key is already saved. Delete it before setting a new one.")
      expect(encrypted_value.reload.sealed_blob&.wrapped_key).to eq("old")
    end

    it "streams an alert when no EncryptedValue exists yet", :db do
      sign_in(user)
      patch profile_byok_key_path, params: { byok_key: envelope }, headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("No keypair")
    end

    it "streams an exact alert on a malformed envelope, without touching the stored key", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value, owner: user, value_type: value_type, sealed_value: nil)
      sign_in(user)

      patch profile_byok_key_path, params: { byok_key: { wrapped_key: "only-this" } }, headers: turbo_headers

      expect(response.body).to include("Could not save that key.")
      expect(encrypted_value.reload.sealed_value).to be_nil
    end

    it "redirects unauthenticated users", :db do
      patch profile_byok_key_path, params: { byok_key: envelope }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /profile/byok_key" do
    it "tears the EncryptedValue and its keypair fully down to the neutral state", :ai_credential, db: true do
      encrypted_value = create(
        :encrypted_value, owner: user, value_type: value_type,
        sealed_value: { wrapped_key: "w", iv: "i", ciphertext: "c" }.to_json
      )
      public_key = encrypted_value.public_key
      private_key = create(:private_key, public_key_id: public_key.id)
      sign_in(user)

      delete profile_byok_key_path, headers: turbo_headers

      expect(EncryptedValue.find_by(id: encrypted_value.id)).to be_nil
      expect(PublicKey.find_by(id: public_key.id)).to be_nil
      expect(PrivateKey.find_by(id: private_key.id)).to be_nil
      expect(user.reload.ai_key_present?).to be(false)
    end

    it "streams the neutral control, the game-controls section, and an exact success toast", :ai_credential, db: true do
      create(:encrypted_value, owner: user, value_type: value_type,
        sealed_value: { wrapped_key: "w", iv: "i", ciphertext: "c" }.to_json)
      sign_in(user)

      delete profile_byok_key_path, headers: turbo_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Set up encryption")
      expect(response.body).to include("game_controls")
      expect(response.body).to include("OpenRouter key deleted.")
    end

    it "is a no-op that still succeeds when no EncryptedValue exists", :ai_credential, db: true do
      sign_in(user)

      expect { delete profile_byok_key_path, headers: turbo_headers }.not_to change(EncryptedValue, :count)
      expect(response.body).to include("OpenRouter key deleted.")
    end

    it "leaves another owner's key untouched", :ai_credential, db: true do
      other = create(:encrypted_value, owner: create(:user), value_type: value_type,
        sealed_value: { wrapped_key: "w", iv: "i", ciphertext: "c" }.to_json)
      create(:encrypted_value, owner: user, value_type: value_type)
      sign_in(user)

      delete profile_byok_key_path, headers: turbo_headers

      expect(EncryptedValue.find_by(id: other.id)).to be_present
    end

    it "redirects unauthenticated users", :db do
      delete profile_byok_key_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
