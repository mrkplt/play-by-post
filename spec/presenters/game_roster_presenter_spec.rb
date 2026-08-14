require "rails_helper"

RSpec.describe GameRosterPresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:current_user) { build_stubbed(:user) }
  let(:game_presenter) { GamePresenter.new(game, policy: policy) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(game_presenter, current_user: current_user, urls: urls) }

  describe "#inactive_character_count" do
    it "counts archived characters visible to the viewer" do
      allow(game).to receive_message_chain(:characters, :archived, :visible_to, :count).and_return(2)
      expect(presenter.inactive_character_count).to eq(2)
    end
  end

  describe "#inactive_characters?" do
    it "is true when there is at least one inactive character" do
      allow(game).to receive_message_chain(:characters, :archived, :visible_to, :count).and_return(1)
      expect(presenter.inactive_characters?).to be(true)
    end

    it "is false when there are no inactive characters" do
      allow(game).to receive_message_chain(:characters, :archived, :visible_to, :count).and_return(0)
      expect(presenter.inactive_characters?).to be(false)
    end
  end

  describe "#banned_members" do
    it "is empty when the viewer cannot manage the game, without querying banned members" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(game).not_to receive(:game_members)

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
    end

    it "constructs each row with the game and injected urls, not a bare model" do
      allow(policy).to receive(:manage?).and_return(true)
      banned = build_stubbed(:game_member, :banned)
      where_rel = double("banned rel")
      includes_rel = double("includes rel")
      allow(game).to receive(:game_members).and_return(double(where: where_rel))
      allow(where_rel).to receive(:includes).with(:user).and_return(includes_rel)
      allow(includes_rel).to receive(:to_a).and_return([ banned ])
      allow(BannedMemberPresenter).to receive(:new).and_call_original

      presenter.banned_members

      expect(BannedMemberPresenter).to have_received(:new).with(banned, game: game, urls: urls)
    end

    it "queries by banned status specifically" do
      allow(policy).to receive(:manage?).and_return(true)
      members_rel = double("members rel")
      includes_rel = double("includes rel")
      allow(game).to receive(:game_members).and_return(members_rel)
      allow(members_rel).to receive(:where).with(status: "banned").and_return(double(includes: includes_rel))
      allow(includes_rel).to receive(:to_a).and_return([])

      presenter.banned_members

      expect(members_rel).to have_received(:where).with(status: "banned")
    end
  end

  describe "#banned_members_section?" do
    it "is false when the viewer cannot manage the game, even with banned members present" do
      allow(policy).to receive(:manage?).and_return(false)
      banned = build_stubbed(:game_member, :banned)
      allow(presenter).to receive(:banned_members).and_return([ banned ])

      expect(presenter.banned_members_section?).to be(false)
    end

    it "is false when the viewer can manage but there are no banned members" do
      allow(policy).to receive(:manage?).and_return(true)
      allow(presenter).to receive(:banned_members).and_return([])

      expect(presenter.banned_members_section?).to be(false)
    end

    it "is true when the viewer can manage and there is a banned member" do
      allow(policy).to receive(:manage?).and_return(true)
      banned = build_stubbed(:game_member, :banned)
      allow(presenter).to receive(:banned_members).and_return([ banned ])

      expect(presenter.banned_members_section?).to be(true)
    end
  end

  describe "#banned_member_last?" do
    it "is true only for the final index" do
      allow(policy).to receive(:manage?).and_return(true)
      banned = build_stubbed(:game_member, :banned)
      where_rel = double("banned rel")
      includes_rel = double("includes rel")
      allow(game).to receive(:game_members).and_return(double(where: where_rel))
      allow(where_rel).to receive(:includes).with(:user).and_return(includes_rel)
      allow(includes_rel).to receive(:to_a).and_return([ banned ])

      expect(presenter.banned_member_last?(0)).to be(true)
      expect(presenter.banned_member_last?(-1)).to be(false)
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

  describe "#roster_characters?" do
    it "is false when there are no roster characters" do
      allow(game).to receive_message_chain(:game_members, :where, :pluck, :to_set).and_return(Set.new)
      allow(game).to receive_message_chain(:characters, :active, :visible_to, :includes, :order, :to_a).and_return([])

      expect(presenter.roster_characters?).to be(false)
    end

    it "is true when there is at least one roster character" do
      character = build_stubbed(:character)
      allow(game).to receive_message_chain(:game_members, :where, :pluck, :to_set).and_return(Set.new)
      allow(game).to receive_message_chain(:characters, :active, :visible_to, :includes, :order, :to_a)
        .and_return([ character ])

      expect(presenter.roster_characters?).to be(true)
    end
  end

  describe "#roster_character_last?" do
    it "is true only for the final index" do
      character = build_stubbed(:character)
      allow(game).to receive_message_chain(:game_members, :where, :pluck, :to_set).and_return(Set.new)
      allow(game).to receive_message_chain(:characters, :active, :visible_to, :includes, :order, :to_a)
        .and_return([ character ])

      expect(presenter.roster_character_last?(0)).to be(true)
      expect(presenter.roster_character_last?(-1)).to be(false)
    end
  end
end
