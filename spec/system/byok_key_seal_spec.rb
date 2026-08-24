require "rails_helper"

# Exercises the real paste -> WebCrypto seal -> submit flow in a genuine
# browser (Capybara + playwright driver runs real Chromium, so
# crypto.subtle actually runs here, unlike a rack-test/headless-JS-less
# driver). Asserts the browser never sends the plaintext key and that the
# resulting envelope is exactly what Crypto::CryptoService can decrypt —
# proving interop with the server side beyond what a fixture-posting request
# spec alone can show, since the browser generates the wrapped key at
# runtime rather than replaying a fixture.
#
# Also proves the lifecycle requirement (Fizzy #120): generate -> save ->
# delete all resolve in place. A dataset marker on <body> distinguishes
# in-place Turbo Stream/Frame updates (body survives) from a full page load
# or Turbo visit (body replaced, marker gone).
RSpec.describe "BYOK key sealing (AI Control Plane)", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:value_type) { "openrouter_key" }

  before { sign_in_as(user) }

  def mark_body
    page.execute_script("document.body.dataset.stayedInPlace = 'yes'")
  end

  def expect_no_page_replacement
    expect(page.evaluate_script("document.body.dataset.stayedInPlace")).to eq("yes")
  end

  it "runs the whole generate -> save -> delete lifecycle in place, never replacing the page", :ai_credential do
    visit profile_path
    mark_body

    click_on "Set up encryption"
    expect(page).to have_css("[data-controller='byok-key-seal']")

    find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
    click_on "Save key"
    expect(page).to have_button("Delete key")
    expect(page).to have_text(/fund ai for your games/i)

    click_on "Delete key"
    expect(page).to have_button("Set up encryption")
    expect(page).not_to have_text(/fund ai for your games/i)

    expect_no_page_replacement
    expect(user.reload.ai_key_present?).to be(false)
  end

  # The inline test adapter finishes KeypairGenerationJob inside #create, so the
  # pending branch would never render. Deferring the job (:test adapter) puts the
  # controller on the pending path production takes while the worker is still
  # running; performing the job mid-poll then proves the spinner's frame poll
  # picks the finished keypair up and resolves to the form — no reload.
  describe "while the keypair job is still running" do
    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "resolves the pending spinner to the paste form by polling", :ai_credential do
      visit profile_path
      mark_body
      click_on "Set up encryption"

      expect(page).to have_css("[data-controller='frame-poll']")

      # The worker finishes while the spinner is polling.
      KeypairGenerationJob.perform_now(owner_type: "User", owner_id: user.id, value_type: value_type)

      expect(page).to have_css("[data-controller='byok-key-seal']", wait: 5)
      expect_no_page_replacement
    end
  end

  it "shows the set-up-encryption step before any keypair exists" do
    visit profile_path

    expect(page).to have_button("Set up encryption")
    expect(page).not_to have_css("[data-controller='byok-key-seal']")
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

      expect(page).to have_button("Delete key")

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

      expect(page).to have_button("Delete key")
      expect(user.reload.ai_key_present?).to be(true)
    end

    it "once saved, shows a delete button and no key input — the key can't be shown or re-pasted" do
      visit profile_path
      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"

      expect(page).to have_button("Delete key")
      expect(page).not_to have_field(type: "password")
      expect(page).not_to have_button("Save key")
      expect(page).not_to have_button("Replace key")
    end

    it "deleting a saved key returns the control to the neutral set-up-encryption state", :ai_credential do
      visit profile_path
      find("[data-byok-key-seal-target='plaintext']").fill_in(with: "sk-or-v1-test-key-abc123")
      click_on "Save key"
      expect(page).to have_button("Delete key")

      click_on "Delete key"

      expect(page).to have_button("Set up encryption")
      expect(user.reload.ai_key_present?).to be(false)
      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_nil
    end
  end
end
