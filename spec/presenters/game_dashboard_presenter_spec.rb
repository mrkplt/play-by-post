require "rails_helper"

RSpec.describe GameDashboardPresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }
  let(:membership) { build_stubbed(:game_member, game: game, user: user) }

  subject(:presenter) do
    described_class.new(
      [ membership ],
      current_user: user,
      can_manage_by_game_id: { game.id => true },
      games_with_new_activity: []
    )
  end

  describe "#empty?" do
    it "is true for no memberships" do
      empty_presenter = described_class.new([], current_user: user, can_manage_by_game_id: {},
        games_with_new_activity: [])
      expect(empty_presenter.empty?).to be(true)
    end

    it "is false when there is at least one membership" do
      expect(presenter.empty?).to be(false)
    end
  end

  describe "#items" do
    it "wraps each membership in a GameDashboardItemPresenter" do
      items = presenter.items
      expect(items.length).to eq(1)
      expect(items.first).to be_a(GameDashboardItemPresenter)
      expect(items.first.game).to eq(game)
    end

    it "resolves can_manage? from the per-game lookup" do
      expect(presenter.items.first.can_manage?).to be(true)
    end
  end
end
