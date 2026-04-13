require "rails_helper"

RSpec.describe UserPresenter do
  let(:user) { build_stubbed(:user, email: "jane@example.com") }

  subject(:presenter) { described_class.new(user) }

  describe "#display_name_or_email" do
    context "when the user has a display name" do
      before { allow(user).to receive(:display_name).and_return("Lady Ashford") }

      it { expect(presenter.display_name_or_email).to eq("Lady Ashford") }
    end

    context "when the user has no display name" do
      before { allow(user).to receive(:display_name).and_return(nil) }

      it "returns the email prefix" do
        expect(presenter.display_name_or_email).to eq("jane")
      end
    end
  end

  describe "#games_by_recent_activity" do
    let(:user) { create(:user) }

    subject(:presenter) { described_class.new(user) }

    it "returns games where user is an active member" do
      game = create(:game)
      create(:game_member, user: user, game: game, status: "active")

      expect(presenter.games_by_recent_activity.map(&:id)).to include(game.id)
    end

    it "excludes games where user is removed" do
      game = create(:game)
      create(:game_member, :removed, user: user, game: game)

      expect(presenter.games_by_recent_activity.map(&:id)).not_to include(game.id)
    end

    it "excludes games where user is banned" do
      game = create(:game)
      create(:game_member, :banned, user: user, game: game)

      expect(presenter.games_by_recent_activity.map(&:id)).not_to include(game.id)
    end

    it "orders games by most recent scene activity descending" do
      old_game = create(:game, name: "Old Game")
      create(:game_member, user: user, game: old_game)
      create(:scene, game: old_game, updated_at: 2.days.ago)

      new_game = create(:game, name: "New Game")
      create(:game_member, user: user, game: new_game)
      create(:scene, game: new_game, updated_at: 1.hour.ago)

      expect(presenter.games_by_recent_activity.map(&:id)).to eq([ new_game.id, old_game.id ])
    end

    it "falls back to game created_at when no scenes exist" do
      older_game = create(:game, name: "Older", created_at: 3.days.ago)
      create(:game_member, user: user, game: older_game)

      newer_game = create(:game, name: "Newer", created_at: 1.day.ago)
      create(:game_member, user: user, game: newer_game)

      expect(presenter.games_by_recent_activity.map(&:id)).to eq([ newer_game.id, older_game.id ])
    end

    it "limits results when limit is provided" do
      3.times { |i| create(:game_member, user: user, game: create(:game, name: "Game #{i}")) }

      expect(presenter.games_by_recent_activity(limit: 2).length).to eq(2)
    end

    it "returns all games when no limit is provided" do
      3.times { |i| create(:game_member, user: user, game: create(:game, name: "Game #{i}")) }

      expect(presenter.games_by_recent_activity.length).to eq(3)
    end

    it "includes the game name in the selected fields" do
      game = create(:game, name: "My Special Game")
      create(:game_member, user: user, game: game)

      expect(presenter.games_by_recent_activity.first.name).to eq("My Special Game")
    end

    it "uses left join so games without scenes are included" do
      game = create(:game)
      create(:game_member, user: user, game: game)

      expect(presenter.games_by_recent_activity.map(&:id)).to include(game.id)
    end
  end

  describe "delegation" do
    it "delegates email to the model" do
      expect(presenter.email).to eq("jane@example.com")
    end
  end
end
