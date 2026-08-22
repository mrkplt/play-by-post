require "rails_helper"

RSpec.describe Ui::ByokKeyFormComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  let(:urls) { { endpoint_url: "/profile/byok_key" } }

  describe "no keypair yet" do
    it "shows the set-up-encryption action, not the paste form" do
      view = rendered(key_present: false, public_key_pem: nil, **urls)

      expect(view).to have_button("Set up encryption")
      expect(view).not_to have_css("[data-controller='byok-key-seal']")
    end

    it "#keypair_ready? is false" do
      component = described_class.new(key_present: false, public_key_pem: nil, **urls)

      expect(component.keypair_ready?).to be(false)
    end

    it "#public_key_pem raises rather than silently returning nil — callers must check #keypair_ready? first" do
      component = described_class.new(key_present: false, public_key_pem: nil, **urls)

      expect { component.public_key_pem }.to raise_error(TypeError)
    end
  end

  describe "keypair ready, no key sealed yet" do
    let(:pem) { "-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----" }

    it "renders the paste-and-seal form wired to the byok-key-seal controller" do
      view = rendered(key_present: false, public_key_pem: pem, **urls)

      expect(view).not_to have_button("Set up encryption")
      expect(view).to have_css("[data-controller='byok-key-seal']")
      expect(view).to have_css("form[action='/profile/byok_key'][method='post']")
      expect(view).to have_button("Save key")
    end

    it "carries the public key PEM as the Stimulus value, not as a submitted field" do
      view = rendered(key_present: false, public_key_pem: pem, **urls)

      expect(view).to have_css("[data-byok-key-seal-public-key-value='#{pem}']")
    end

    it "never gives the plaintext input a name attribute" do
      view = rendered(key_present: false, public_key_pem: pem, **urls)

      plaintext_input = view.find("[data-byok-key-seal-target='plaintext']")
      expect(plaintext_input[:name]).to be_nil
    end

    it "includes hidden envelope fields for the Stimulus controller to populate" do
      view = rendered(key_present: false, public_key_pem: pem, **urls)

      expect(view).to have_css("input[type='hidden'][name='byok_key[wrapped_key]']", visible: false)
      expect(view).to have_css("input[type='hidden'][name='byok_key[iv]']", visible: false)
      expect(view).to have_css("input[type='hidden'][name='byok_key[ciphertext]']", visible: false)
    end

    it "#keypair_ready? is true and #public_key_pem returns the PEM" do
      component = described_class.new(key_present: false, public_key_pem: pem, **urls)

      expect(component.keypair_ready?).to be(true)
      expect(component.public_key_pem).to eq(pem)
    end

    it "#heading and #status_text carry the not-yet-configured copy" do
      component = described_class.new(key_present: false, public_key_pem: pem, **urls)

      expect(component.heading).to eq("Bring your own OpenRouter key")
      expect(component.status_text).to eq("No key configured yet.")
    end
  end

  describe "a key is already present" do
    let(:pem) { "-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----" }

    it "shows a delete button and no key input — a stored key can't be retrieved or re-pasted" do
      view = rendered(key_present: true, public_key_pem: pem, **urls)

      expect(view).to have_button("Delete key")
      expect(view).not_to have_button("Save key")
      expect(view).not_to have_button("Replace key")
      expect(view).not_to have_css("input[type='password']")
      expect(view).not_to have_css("[data-controller='byok-key-seal']")
    end

    it "the delete button issues a DELETE to the delete_url" do
      view = rendered(key_present: true, public_key_pem: pem, **urls)

      expect(view).to have_css("form[action='/profile/byok_key'] input[name='_method'][value='delete']", visible: false)
    end

    it "#heading and #status_text carry the saved copy, without implying the key can be shown" do
      component = described_class.new(key_present: true, public_key_pem: pem, **urls)

      expect(component.heading).to eq("OpenRouter key")
      expect(component.status_text).to eq("A key is saved. It can't be shown again — delete it to set a new one.")
    end
  end
end
