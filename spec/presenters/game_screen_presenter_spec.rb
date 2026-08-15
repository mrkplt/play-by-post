require "rails_helper"

# The parts are real presenters rather than doubles: the constructor is sig'd
# with concrete types, which sorbet-runtime enforces at runtime.
RSpec.describe GameScreenPresenter, :db do
  let(:game_record) { create(:game) }
  let(:viewer) { create(:user, :with_profile) }
  let(:game) { GamePresenter.new(game_record, policy: GamePolicy.new(viewer, game_record)) }
  let(:viewer_context) do
    described_class::Viewer.new(current_user: viewer, urls: urls, helpers: helpers_double)
  end
  let(:urls) { double("urls") }
  let(:helpers_double) { double("helpers") }

  describe ".build" do
    it "builds the screen over the given game presenter" do
      expect(described_class.build(game, viewer_context).game).to be(game)
    end

    it "builds the show panel" do
      expect(described_class.build(game, viewer_context).show).to be_a(GameShowPresenter)
    end

    it "builds the roster panel" do
      expect(described_class.build(game, viewer_context).roster).to be_a(GameRosterPresenter)
    end

    it "builds the scenes panel" do
      expect(described_class.build(game, viewer_context).scenes).to be_a(GameScenesPanelPresenter)
    end

    it "gives every panel the same game presenter, so they cannot disagree" do
      screen = described_class.build(game, viewer_context)

      expect(screen.show.__getobj__).to be(game)
      expect(screen.roster.__getobj__).to be(game)
      expect(screen.scenes.__getobj__).to be(game)
    end
  end

  describe "the parts it carries" do
    def screen
      described_class.new(
        game,
        show: GameShowPresenter.new(game, current_user: viewer, urls: urls, helpers: helpers_double),
        roster: GameRosterPresenter.new(game, current_user: viewer, urls: urls),
        scenes: GameScenesPanelPresenter.new(game, current_user: viewer)
      )
    end

    it "exposes the game as its subject" do
      expect(screen.game).to be(game)
    end

    it "exposes the show panel" do
      expect(screen.show).to be_a(GameShowPresenter)
    end

    it "exposes the roster panel" do
      expect(screen.roster).to be_a(GameRosterPresenter)
    end

    it "exposes the scenes panel" do
      expect(screen.scenes).to be_a(GameScenesPanelPresenter)
    end

    # BasePresenter is a SimpleDelegator, so anything not answered here falls
    # through to the game presenter.
    it "delegates unknown messages to the game presenter" do
      expect(screen.name).to eq(game_record.name)
    end
  end
end
