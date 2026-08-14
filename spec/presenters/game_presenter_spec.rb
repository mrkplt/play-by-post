require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(game, policy: policy, urls: urls) }

  describe "#can_manage?" do
    it "is true when the injected policy allows management" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected policy disallows management" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#pending_invitations" do
    it "returns the game's pending invitations, newest first, wrapped as presenters" do
      invitation = build_stubbed(:invitation)
      ordered = [ invitation ]
      all_rel = double("all invitations")
      pending_rel = double("pending invitations")
      ordered_rel = double("ordered invitations")
      allow(game).to receive(:invitations).and_return(all_rel)
      allow(all_rel).to receive(:pending).and_return(pending_rel)
      allow(pending_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.pending_invitations
      expect(result).to all(be_a(InvitationPresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
    end
  end

  describe "#pages" do
    it "returns the game's pages ordered by title, wrapped as presenters" do
      page = build_stubbed(:page)
      ordered = [ page ]
      all_rel = double("all pages")
      ordered_rel = double("ordered pages")
      allow(game).to receive(:pages).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:title).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.pages
      expect(result).to all(be_a(PagePresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
    end
  end

  describe "#links" do
    it "returns the game's links newest first, wrapped as presenters" do
      link = build_stubbed(:game_link)
      ordered = [ link ]
      all_rel = double("all links")
      ordered_rel = double("ordered links")
      allow(game).to receive(:game_links).and_return(all_rel)
      allow(all_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.links
      expect(result).to all(be_a(GameLinkPresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
    end
  end

  describe "#notebook_board" do
    it "wraps the game in a NotebookBoardPresenter" do
      expect(presenter.notebook_board).to be_a(NotebookBoardPresenter)
    end
  end

  describe "#images_disabled?" do
    it "is true when the game has images disabled" do
      allow(game).to receive(:images_disabled?).and_return(true)
      expect(presenter.images_disabled?).to be(true)
    end

    it "is false when the game has images enabled" do
      allow(game).to receive(:images_disabled?).and_return(false)
      expect(presenter.images_disabled?).to be(false)
    end
  end

  describe "#errors?" do
    it "is false on a clean game" do
      expect(presenter.errors?).to be(false)
    end

    it "is true when the game has errors" do
      game.errors.add(:name, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns the game's full error messages" do
      game.errors.add(:name, "can't be blank")
      expect(presenter.error_messages).to include("Name can't be blank")
    end
  end

  describe "#ai_summaries_enabled?" do
    it "delegates to the model" do
      allow(game).to receive(:ai_summaries_enabled?).and_return(true)
      expect(presenter.ai_summaries_enabled?).to be(true)
    end
  end

  describe "#id" do
    it "delegates to the model" do
      expect(presenter.id).to eq(game.id)
    end
  end

  describe "#description" do
    it "delegates to the model" do
      expect(presenter.description).to eq(game.description)
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end

  describe "with a current_user and helpers" do
    let(:current_user) { build_stubbed(:user) }
    let(:helpers) { double("helpers") }

    subject(:presenter) do
      described_class.new(game, policy: policy, urls: urls, current_user: current_user, helpers: helpers)
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
      it "returns the game's files, newest first, wrapped as presenters" do
        file = build_stubbed(:game_file)
        includes_rel = double("includes rel")
        ordered_rel = double("ordered rel")
        allow(game).to receive(:game_files).and_return(double(includes: includes_rel))
        allow(includes_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
        allow(ordered_rel).to receive(:to_a).and_return([ file ])

        result = presenter.game_files
        expect(result.length).to eq(1)
        expect(result.first).to be_a(GameFilePresenter)
      end
    end

    describe "#new_game_file" do
      it "returns a blank file record wrapped for the upload form" do
        blank = build_stubbed(:game_file)
        allow(game).to receive(:game_files).and_return(double(new: blank))

        expect(presenter.new_game_file).to be_a(GameFilePresenter)
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
        allow(current_user).to receive(:user_profile).and_return(nil)
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
end
