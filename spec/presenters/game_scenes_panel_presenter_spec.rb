require "rails_helper"

RSpec.describe GameScenesPanelPresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:current_user) { build_stubbed(:user) }
  let(:game_presenter) { GamePresenter.new(game, policy: policy) }

  subject(:presenter) { described_class.new(game_presenter, current_user: current_user) }

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

    it "active_scenes? is true when there are active scenes" do
      expect(presenter.active_scenes?).to be(true)
    end

    it "roster_preview_empty? is true when the roster preview has no rows" do
      sp = double("scene_participant", character: nil)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.roster_preview_empty?).to be(true)
    end

    it "roster_preview_empty? is false when the roster preview has rows" do
      character = build_stubbed(:character, name: "Vex")
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.roster_preview_empty?).to be(false)
    end

    it "gm_row_position is :last when the roster preview is empty" do
      sp = double("scene_participant", character: nil)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.gm_row_position).to eq(:last)
    end

    it "gm_row_position is :middle when the roster preview has rows" do
      character = build_stubbed(:character, name: "Vex")
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.gm_row_position).to eq(:middle)
    end

    it "roster_preview_position is :last only for the final index" do
      character = build_stubbed(:character, name: "Vex")
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.roster_preview_position(0)).to eq(:last)
      expect(presenter.roster_preview_position(-1)).to eq(:middle)
    end
  end

  describe "#active_scenes?" do
    it "is false when there are no active scenes" do
      allow(game).to receive_message_chain(:scenes, :visible_to, :active, :includes, :to_a).and_return([])
      allow(current_user).to receive(:user_profile).and_return(nil)

      expect(presenter.active_scenes?).to be(false)
    end
  end
end
