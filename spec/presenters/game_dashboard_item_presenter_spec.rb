require "rails_helper"

RSpec.describe GameDashboardItemPresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }
  let(:membership) { build_stubbed(:game_member, game: game, user: user) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }

  subject(:presenter) do
    described_class.new(
      membership,
      current_user: user,
      policy: policy,
      can_manage: true,
      games_with_new_activity: [ game.id ]
    )
  end

  describe "#game" do
    it "wraps the membership's game in a GamePresenter carrying the same policy" do
      result = presenter.game
      expect(result).to be_a(GamePresenter)
      expect(result.can_manage?).to be(true)
    end
  end

  describe "#can_manage?" do
    it "reads the precomputed can_manage option" do
      expect(described_class.new(membership, current_user: user, policy: policy, can_manage: true,
        games_with_new_activity: []).can_manage?).to be(true)
      expect(described_class.new(membership, current_user: user, policy: policy, can_manage: false,
        games_with_new_activity: []).can_manage?).to be(false)
    end
  end

  describe "#former?" do
    it "is true for a removed membership" do
      removed = build_stubbed(:game_member, :removed, game: game, user: user)
      expect(described_class.new(removed, current_user: user, policy: policy, can_manage: true,
        games_with_new_activity: []).former?).to be(true)
    end

    it "is false for an active membership" do
      expect(presenter.former?).to be(false)
    end
  end

  describe "#character_label" do
    it "is nil when the viewer has no character in the game" do
      allow(game).to receive_message_chain(:characters, :active, :where, :to_a).and_return([])
      expect(presenter.character_label).to be_nil
    end

    it "is just the character's name when there is exactly one" do
      character = build_stubbed(:character, name: "Vex")
      allow(game).to receive_message_chain(:characters, :active, :where, :to_a).and_return([ character ])
      expect(presenter.character_label).to eq("Vex")
    end

    it "appends a +N count when there is more than one character" do
      characters = [ build_stubbed(:character, name: "Vex"), build_stubbed(:character, name: "Grog") ]
      allow(game).to receive_message_chain(:characters, :active, :where, :to_a).and_return(characters)
      expect(presenter.character_label).to eq("Vex +1")
    end
  end

  describe "#active_scene_count" do
    it "counts the game's unresolved scenes" do
      allow(game).to receive_message_chain(:scenes, :where, :count).and_return(3)
      expect(presenter.active_scene_count).to eq(3)
    end
  end

  describe "#new_activity?" do
    it "is true when the game id is in games_with_new_activity" do
      expect(presenter.new_activity?).to be(true)
    end

    it "is false when the game id is absent" do
      other = described_class.new(membership, current_user: user, policy: policy, can_manage: true,
        games_with_new_activity: [])
      expect(other.new_activity?).to be(false)
    end
  end
end
