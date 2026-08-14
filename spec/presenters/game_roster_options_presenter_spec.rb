require "rails_helper"

RSpec.describe GameRosterOptionsPresenter do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  subject(:presenter) { described_class.new(game_presenter) }

  describe "#owner_options" do
    it "is empty when the game has no active players" do
      members_rel = double("members rel")
      where_rel = double("where rel")
      allow(game).to receive(:active_members).and_return(members_rel)
      allow(members_rel).to receive(:where).with(role: "player").and_return(where_rel)
      allow(where_rel).to receive(:includes).with(:user).and_return([])

      expect(presenter.owner_options).to eq([])
    end

    it "pairs each active player's display name (falling back to email) with their id" do
      named = build_stubbed(:user, email: "elf@example.com")
      allow(named).to receive(:display_name).and_return("Elrond")
      nameless = build_stubbed(:user, email: "orc@example.com")
      allow(nameless).to receive(:display_name).and_return(nil)

      named_membership = instance_double(GameMember, user: named)
      nameless_membership = instance_double(GameMember, user: nameless)

      members_rel = double("members rel")
      where_rel = double("where rel")
      allow(game).to receive(:active_members).and_return(members_rel)
      allow(members_rel).to receive(:where).with(role: "player").and_return(where_rel)
      allow(where_rel).to receive(:includes).with(:user).and_return([ named_membership, nameless_membership ])

      expect(presenter.owner_options).to eq([ [ "Elrond", named.id ], [ "orc@example.com", nameless.id ] ])
    end
  end
end
