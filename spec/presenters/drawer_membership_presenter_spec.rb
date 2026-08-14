require "rails_helper"

RSpec.describe DrawerMembershipPresenter do
  let(:game) { build_stubbed(:game, name: "Sunken Archive") }
  let(:user) { build_stubbed(:user) }

  def present(member, active_game_id: nil)
    described_class.new(member, active_game_id: active_game_id)
  end

  describe "#game_name" do
    it "returns the game's name" do
      member = build_stubbed(:game_member, game: game, user: user, role: "player", status: "active")
      expect(present(member).game_name).to eq("Sunken Archive")
    end
  end

  describe "#game_id" do
    it "returns the game's id, for the drawer's route" do
      member = build_stubbed(:game_member, game: game, user: user, role: "player", status: "active")
      expect(present(member).game_id).to eq(game.id)
    end
  end

  describe "#active?" do
    let(:member) { build_stubbed(:game_member, game: game, user: user, role: "player", status: "active") }

    it "is true when the row's game is the one being viewed" do
      expect(present(member, active_game_id: game.id).active?).to be(true)
    end

    it "is false for a different game" do
      expect(present(member, active_game_id: game.id + 1).active?).to be(false)
    end

    it "is false when no game is active" do
      expect(present(member, active_game_id: nil).active?).to be(false)
    end
  end

  describe "#status_icon" do
    it "is :crown for a game the viewer runs" do
      member = build_stubbed(:game_member, game: game, user: user, role: "game_master", status: "active")
      expect(present(member).status_icon).to eq(:crown)
    end

    it "is :moon for a game the viewer was removed from" do
      member = build_stubbed(:game_member, game: game, user: user, role: "player", status: "removed")
      expect(present(member).status_icon).to eq(:moon)
    end

    it "is :plain for an ordinary player game" do
      member = build_stubbed(:game_member, game: game, user: user, role: "player", status: "active")
      expect(present(member).status_icon).to eq(:plain)
    end

    it "prefers the crown when a game master was also removed" do
      member = build_stubbed(:game_member, game: game, user: user, role: "game_master", status: "removed")
      expect(present(member).status_icon).to eq(:crown)
    end
  end
end
