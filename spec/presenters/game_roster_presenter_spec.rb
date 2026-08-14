require "rails_helper"

RSpec.describe GameRosterPresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:current_user) { build_stubbed(:user) }
  let(:game_presenter) { GamePresenter.new(game, policy: policy) }

  subject(:presenter) { described_class.new(game_presenter, current_user: current_user) }

  describe "#inactive_character_count" do
    it "counts archived characters visible to the viewer" do
      allow(game).to receive_message_chain(:characters, :archived, :visible_to, :count).and_return(2)
      expect(presenter.inactive_character_count).to eq(2)
    end
  end

  describe "#banned_members" do
    it "is empty when the viewer cannot manage the game" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.banned_members).to eq([])
    end

    it "wraps banned members when the viewer can manage the game" do
      allow(policy).to receive(:manage?).and_return(true)
      banned = build_stubbed(:game_member, :banned)
      where_rel = double("banned rel")
      includes_rel = double("includes rel")
      allow(game).to receive(:game_members).and_return(double(where: where_rel))
      allow(where_rel).to receive(:includes).with(:user).and_return(includes_rel)
      allow(includes_rel).to receive(:to_a).and_return([ banned ])

      result = presenter.banned_members
      expect(result.length).to eq(1)
      expect(result.first).to be_a(BannedMemberPresenter)
      expect(result.first.member).to eq(banned)
    end
  end

  describe "#roster_characters" do
    it "wraps active, visible characters, marking removed players" do
      removed_user = build_stubbed(:user)
      character = build_stubbed(:character, user: removed_user)
      allow(game).to receive_message_chain(:game_members, :where, :pluck, :to_set)
        .and_return(Set.new([ removed_user.id ]))
      allow(game).to receive_message_chain(:characters, :active, :visible_to, :includes, :order, :to_a)
        .and_return([ character ])

      result = presenter.roster_characters
      expect(result.length).to eq(1)
      expect(result.first).to be_a(RosterCharacterPresenter)
      expect(result.first.removed?).to be(true)
    end
  end
end
