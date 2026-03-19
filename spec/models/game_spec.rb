require "rails_helper"

RSpec.describe Game, type: :model do
  describe "validations" do
    it "requires a name" do
      game = build(:game, name: nil)
      expect(game).not_to be_valid
      expect(game.errors[:name]).to be_present
    end

    it "enforces max name length of 200" do
      game = build(:game, name: "a" * 201)
      expect(game).not_to be_valid
    end

    it "is valid with a name" do
      expect(build(:game)).to be_valid
    end
  end

  describe "#game_master?" do
    let(:game) { create(:game) }
    let(:gm_user) { create(:user) }
    let(:player_user) { create(:user) }

    before do
      create(:game_member, :game_master, game: game, user: gm_user)
      create(:game_member, game: game, user: player_user)
    end

    it "returns true for the GM" do
      expect(game.game_master?(gm_user)).to be true
    end

    it "returns false for a player" do
      expect(game.game_master?(player_user)).to be false
    end
  end

  describe "#active_member?" do
    let(:game) { create(:game) }
    let(:user) { create(:user) }

    it "returns true for active members" do
      create(:game_member, game: game, user: user, status: "active")
      expect(game.active_member?(user)).to be true
    end

    it "returns false for removed members" do
      create(:game_member, :removed, game: game, user: user)
      expect(game.active_member?(user)).to be false
    end
  end
end
