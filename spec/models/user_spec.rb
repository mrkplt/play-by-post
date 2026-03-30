require "rails_helper"

RSpec.describe User, type: :model do
  describe "#display_name" do
    it "returns display_name from user_profile when profile exists" do
      user = create(:user, :with_profile)
      expect(user.display_name).to eq(user.user_profile.display_name)
    end

    it "returns nil when no profile exists" do
      user = create(:user)
      expect(user.display_name).to be_nil
    end
  end

  describe "associations" do
    it "has many game_members" do
      user = create(:user)
      game = create(:game)
      member = create(:game_member, user: user, game: game)
      expect(user.game_members).to include(member)
    end

    it "has many games through game_members" do
      user = create(:user)
      game = create(:game)
      create(:game_member, user: user, game: game)
      expect(user.games).to include(game)
    end
  end

  describe "#games_by_recent_activity" do
    let(:user) { create(:user) }

    it "returns games where user is an active member" do
      game = create(:game)
      create(:game_member, user: user, game: game, status: "active")

      result = user.games_by_recent_activity
      expect(result.map(&:id)).to include(game.id)
    end

    it "excludes games where user is removed" do
      game = create(:game)
      create(:game_member, :removed, user: user, game: game)

      result = user.games_by_recent_activity
      expect(result.map(&:id)).not_to include(game.id)
    end

    it "excludes games where user is banned" do
      game = create(:game)
      create(:game_member, :banned, user: user, game: game)

      result = user.games_by_recent_activity
      expect(result.map(&:id)).not_to include(game.id)
    end

    it "orders games by most recent scene activity descending" do
      old_game = create(:game, name: "Old Game")
      create(:game_member, user: user, game: old_game)
      create(:scene, game: old_game, updated_at: 2.days.ago)

      new_game = create(:game, name: "New Game")
      create(:game_member, user: user, game: new_game)
      create(:scene, game: new_game, updated_at: 1.hour.ago)

      result = user.games_by_recent_activity
      expect(result.map(&:id)).to eq([new_game.id, old_game.id])
    end

    it "falls back to game created_at when no scenes exist" do
      older_game = create(:game, name: "Older", created_at: 3.days.ago)
      create(:game_member, user: user, game: older_game)

      newer_game = create(:game, name: "Newer", created_at: 1.day.ago)
      create(:game_member, user: user, game: newer_game)

      result = user.games_by_recent_activity
      expect(result.map(&:id)).to eq([newer_game.id, older_game.id])
    end

    it "limits results when limit is provided" do
      3.times do |i|
        game = create(:game, name: "Game #{i}")
        create(:game_member, user: user, game: game)
      end

      result = user.games_by_recent_activity(limit: 2)
      expect(result.length).to eq(2)
    end

    it "returns all games when no limit is provided" do
      3.times do |i|
        game = create(:game, name: "Game #{i}")
        create(:game_member, user: user, game: game)
      end

      result = user.games_by_recent_activity
      expect(result.length).to eq(3)
    end

    it "includes the game name in the selected fields" do
      game = create(:game, name: "My Special Game")
      create(:game_member, user: user, game: game)

      result = user.games_by_recent_activity.first
      expect(result.name).to eq("My Special Game")
    end

    it "uses left join so games without scenes are included" do
      game = create(:game)
      create(:game_member, user: user, game: game)

      result = user.games_by_recent_activity
      expect(result.map(&:id)).to include(game.id)
    end
  end
end
