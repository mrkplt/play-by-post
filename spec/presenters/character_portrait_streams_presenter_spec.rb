require "rails_helper"

# CharacterPortraitStreamsPresenter builds the Turbo Streams the portrait
# control answers with. Rendered through a real view context so the stream
# HTML (targets + content) is asserted.
RSpec.describe CharacterPortraitStreamsPresenter, type: :request do
  let(:game) { create(:game) }
  let(:player) { create(:user, :with_profile) }
  let(:character) { create(:character, game: game, user: player) }

  # A view context that can build the turbo streams and render components.
  def presenter
    view = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create }.view_context
    described_class.new(character: character, game: game, generate_url: "/generate", helpers: view)
  end

  describe "#control" do
    it "replaces the control target with the pending spinner when pending" do
      html = presenter.control(described_class::State.new(pending: true))

      expect(html).to include("turbo-stream", %(target="#{described_class::CONTROL_TARGET}"), "portrait-poll")
    end

    it "replaces the control with the form (and reason) when failed" do
      html = presenter.control(described_class::State.new(failure_reason: "blocked"))

      expect(html).to include("blocked")
      expect(html).to include("action=\"/generate\"")
    end
  end

  describe "#settled" do
    it "replaces control + library + a success toast when there is no failure" do
      streams = presenter.settled(failure_reason: nil).join

      expect(streams).to include(described_class::CONTROL_TARGET, described_class::LIBRARY_TARGET, described_class::TOAST_TARGET)
      expect(streams).to include("Portrait generated")
    end

    it "uses the failure reason in the toast when failed" do
      streams = presenter.settled(failure_reason: "It broke").join

      expect(streams).to include("It broke")
    end
  end
end
