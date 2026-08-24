require "rails_helper"

# Exercises the real paste -> WebCrypto seal -> submit flow in a genuine
# browser (Capybara + playwright driver runs real Chromium, so
# crypto.subtle actually runs here, unlike a rack-test/headless-JS-less
# driver). Asserts the browser never sends the plaintext key and that the
# resulting envelope is exactly what Crypto::CryptoService can decrypt —
# proving interop with the server side beyond what a fixture-posting request
# spec alone can show, since the browser generates the wrapped key at
# runtime rather than replaying a fixture.
RSpec.describe "BYOK key sealing (AI Control Plane)", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:value_type) { "openrouter_key" }

  before { sign_in_as(user) }

  it "shows the set-up-encryption step before any keypair exists" do
    visit profile_path

    expect(page).to have_button("Set up encryption")
    expect(page).not_to have_css("[data-controller='byok-key-seal']")
  end

  it "generating a keypair reveals the paste-and-seal form (job runs inline in test)", :ai_credential do
    visit profile_path

    click_on "Set up encryption"

    expect(page).to have_css("[data-controller='byok-key-seal']")
    expect(page).to have_field(type: "password")
    expect(page).to have_button("Save key")
  end

  # Regression for the enqueue-vs-subscribe race (Fizzy #120): KeypairGenerationJob
  # can finish — and broadcast the paste form — before the browser's subscription
  # is confirmed, so the broadcast is dropped and the spinner hung forever.
  # ByokKeyChannel replays the broadcast on subscribe, so the spinner still
  # resolves. The inline test adapter reproduces the race exactly (the job always
  # wins: it runs, and its broadcast is dropped, inside #create before the spinner
  # even renders); stubbing keypair_exists? false holds the controller on the
  # pending path it would have taken in production's racy window.
  it "resolves the pending spinner when the job finishes before the subscription", :ai_credential do
    allow_any_instance_of(Profiles::ByokKeysController).to receive(:keypair_exists?).and_return(false)

    visit profile_path
    click_on "Set up encryption"

    expect(page).to have_css("[data-controller='byok-key-seal']")
    expect(page).to have_button("Save key")
  end

  describe "with a keypair already generated" do
    # A real RSA-2048 keypair, not the factory's placeholder PEM: WebCrypto's
    # importKey rejects non-key material, and this spec's whole point is
    # proving the browser's real crypto.subtle output decrypts server-side —
    # a fake PEM would only prove the form renders.
    let(:generated) { Crypto::KeypairGenerator.call }

    before do
      public_key = create(:public_key, public_key: generated.public_key_pem, fingerprint: generated.fingerprint)
      create(:encrypted_value, owner: user, value_type: value_type, public_key: public_key)
    end

    it "encrypts the pasted key client-side and stores only the sealed envelope" do
      visit profile_path

      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"

      expect(page).to have_current_path(profile_path)

      encrypted_value = EncryptedValue.find_by(owner: user, value_type: value_type)
      blob = encrypted_value.sealed_blob
      expect(blob).to be_present
      expect(blob.ciphertext).not_to include("sk-or-v1-test-key-abc123")

      plaintext = Crypto::CryptoService.new(generated.private_key_pem).decrypt(blob)
      expect(plaintext).to eq("sk-or-v1-test-key-abc123")
    end

    it "marks the BYOK key as present once sealed" do
      visit profile_path

      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"

      expect(user.reload.ai_key_present?).to be(true)
    end

    it "once saved, shows a delete button and no key input — the key can't be shown or re-pasted" do
      visit profile_path
      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"

      visit profile_path
      expect(page).to have_button("Delete key")
      expect(page).not_to have_field(type: "password")
      expect(page).not_to have_button("Save key")
      expect(page).not_to have_button("Replace key")
    end

    it "deleting a saved key returns the control to the neutral set-up-encryption state", :ai_credential do
      visit profile_path
      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"

      visit profile_path
      click_on "Delete key"

      expect(page).to have_button("Set up encryption")
      expect(user.reload.ai_key_present?).to be(false)
      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_nil
    end
  end
end
