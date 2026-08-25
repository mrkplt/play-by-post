require "rails_helper"

# The Turbo Stream assemblies Profiles::ByokKeysController answers with. Built
# against a real view context so the streams render exactly what the browser
# receives.
RSpec.describe ByokKeyStreams, type: :model do
  let(:user) { create(:user, :with_profile) }
  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end
  let(:flash) { ActionDispatch::Flash::FlashHash.new }

  def streams
    described_class.new(
      user: user,
      context: described_class::Context.new(
        turbo_stream: Turbo::Streams::TagBuilder.new(view_context),
        helpers: view_context,
        flash: flash
      ),
      endpoint_url: "/profile/byok_key"
    )
  end

  describe "#creation" do
    it "swaps the control to the polling pending spinner with the toast", :db do
      flash[:notice] = "Preparing your encryption key…"

      control, toast = streams.creation(pending: true)

      expect(control).to include(%(target="#{Ui::ByokKeyFormComponent::FRAME_ID}"))
      expect(control).to include("frame-poll")
      expect(toast).to include(%(target="toast_layer"))
      expect(toast).to include("Preparing your encryption key…")
    end

    it "swaps the control to its persisted state when the keypair already exists", :db do
      create(:encrypted_value, owner: user)

      control, _toast = streams.creation(pending: false)

      expect(control).to include("byok-key-seal")
      expect(control).not_to include("frame-poll")
    end
  end

  describe "#settled" do
    it "swaps the control, the game-controls section, and the toast", :db do
      flash[:notice] = "OpenRouter key deleted."

      control, game_controls, toast = streams.settled

      expect(control).to include(%(target="#{Ui::ByokKeyFormComponent::FRAME_ID}"))
      expect(control).to include("Set up encryption")
      expect(game_controls).to include(%(target="game_controls"))
      expect(game_controls).to include(%(id="game_controls"))
      expect(toast).to include(%(target="toast_layer"))
      expect(toast).to include("OpenRouter key deleted.")
    end
  end

  describe "#component" do
    it "reflects the user's persisted key state", :db do
      create(:encrypted_value, :sealed, owner: user)

      component = streams.component(pending: false)

      expect(component.key_present?).to be(true)
    end

    it "carries the keypair's public half once generated", :db do
      encrypted_value = create(:encrypted_value, owner: user)

      component = streams.component(pending: false)

      expect(component.public_key_pem).to eq(T.must(encrypted_value.public_key).public_key)
    end

    it "renders pending when asked, regardless of persisted state", :db do
      component = streams.component(pending: true)

      expect(component.pending?).to be(true)
    end
  end
end
