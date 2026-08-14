require "rails_helper"

RSpec.describe SceneFormBuilder, :db do
  let(:game) { create(:game) }
  let(:new_scene) { game.scenes.new }
  let(:urls) { double(game_scene_path: "/games/1/scenes/2", game_path: "/games/1") }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  def build_params(hash = {})
    ActionController::Parameters.new(hash)
  end

  describe "#form_component" do
    it "builds a Shared::SceneFormComponent" do
      builder = described_class.new(game, new_scene, build_params, urls)
      expect(builder.form_component(game_presenter)).to be_a(Shared::SceneFormComponent)
    end

    it "marks the form quick when the quick param is present" do
      builder = described_class.new(game, new_scene, build_params(quick: "1"), urls)
      component = builder.form_component(game_presenter)
      expect(component.quick?).to be(true)
    end

    it "resolves the back link to the parent scene when parent_scene_id is present" do
      parent = create(:scene, game: game)
      builder = described_class.new(game, new_scene, build_params(parent_scene_id: parent.id.to_s), urls)

      builder.form_component(game_presenter)
      expect(urls).to have_received(:game_scene_path).with(game, parent.id.to_s)
    end

    it "resolves the back link to the game when there is no parent_scene_id" do
      builder = described_class.new(game, new_scene, build_params, urls)

      builder.form_component(game_presenter)
      expect(urls).to have_received(:game_path).with(game)
    end

    it "includes active scenes and up to three recent resolved scenes as parent options" do
      active = create(:scene, game: game, title: "Active One")
      resolved = create(:scene, :resolved, game: game, title: "Resolved One")

      builder = described_class.new(game, new_scene, build_params, urls)
      component = builder.form_component(game_presenter)

      labels = component.parent_options.map(&:first)
      expect(labels).to include(active.title)
      expect(labels).to include("#{resolved.title} (Resolved)")
    end

    it "includes an active player and their active characters in players_with_characters" do
      user = create(:user)
      create(:game_member, game: game, user: user, role: "player", status: "active")
      character = create(:character, game: game, user: user)

      builder = described_class.new(game, new_scene, build_params, urls)
      component = builder.form_component(game_presenter)

      row = component.players_with_characters.find { |p| p.__getobj__.id == user.id }
      expect(row).not_to be_nil
      expect(row.characters.map { |c| c.__getobj__.id }).to include(character.id)
    end

    it "checks characters resubmitted via character_ids params" do
      builder = described_class.new(game, new_scene, build_params(character_ids: [ "5" ]), urls)
      component = builder.form_component(game_presenter)

      expect(component.selected_character_ids).to include("5")
    end
  end
end
