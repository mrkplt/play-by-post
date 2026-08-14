require "rails_helper"

RSpec.describe GameShowPresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:game_presenter) { GamePresenter.new(game, policy: policy) }

  subject(:presenter) { described_class.new(game_presenter, current_user: user) }

  describe "#can_manage?" do
    it "delegates to the wrapped GamePresenter's capability" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)

      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#gm_name" do
    it "returns the GM's display name when there is a game master" do
      gm_user = build_stubbed(:user)
      gm_member = build_stubbed(:game_member, :game_master, user: gm_user)
      masters_rel = double("game masters")
      allow(game).to receive(:game_members).and_return(double(game_masters: masters_rel))
      allow(masters_rel).to receive(:includes).with(:user).and_return(double(first: gm_member))
      allow(gm_user).to receive(:display_name).and_return("The GM")

      expect(presenter.gm_name).to eq("The GM")
    end

    it "falls back to 'GM' when there is no game master yet" do
      masters_rel = double("game masters")
      allow(game).to receive(:game_members).and_return(double(game_masters: masters_rel))
      allow(masters_rel).to receive(:includes).with(:user).and_return(double(first: nil))

      expect(presenter.gm_name).to eq("GM")
    end
  end

  describe "#game_files" do
    it "returns the game's files, newest first" do
      files = [ build_stubbed(:game_file) ]
      includes_rel = double("includes rel")
      ordered_rel = double("ordered rel")
      allow(game).to receive(:game_files).and_return(double(includes: includes_rel))
      allow(includes_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(files)

      expect(presenter.game_files).to eq(files)
    end
  end

  describe "#new_game_file" do
    it "returns a blank file record for the upload form" do
      blank = build_stubbed(:game_file)
      allow(game).to receive(:game_files).and_return(double(new: blank))

      expect(presenter.new_game_file).to eq(blank)
    end
  end

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

  describe "#active_scenes and #roster_preview" do
    let(:scene) { build_stubbed(:scene, title: "The Ambush") }

    before do
      allow(game).to receive_message_chain(
        :scenes, :visible_to, :active, :includes, :to_a
      ).and_return([ scene ])
      allow(user).to receive(:user_profile).and_return(nil)
    end

    it "wraps each active scene visible to the viewer" do
      expect(presenter.active_scenes).to contain_exactly(an_instance_of(ScenePresenter))
    end

    it "builds the roster preview from each scene's characters, deduped by name" do
      character = build_stubbed(:character, name: "Vex")
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.roster_preview).to eq([ { name: "Vex", scene: "The Ambush" } ])
    end

    it "excludes participants without a character" do
      sp = double("scene_participant", character: nil)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.roster_preview).to eq([])
    end
  end
end
