require "rails_helper"

RSpec.describe Shared::SceneFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { game.scenes.new }
  let(:user) { build_stubbed(:user, :with_profile) }
  let(:character) { build_stubbed(:character, name: "Seraphina Vex", user: user) }
  let(:game_presenter) { GamePresenter.new(game, policy: nil) }
  let(:scene_presenter) { ScenePresenter.new(scene) }

  def build_component(**overrides)
    described_class.new(
      **{
        game: game_presenter,
        scene: scene_presenter,
        players_with_characters: [],
        parent_options: [],
        quick: false,
        selected_character_ids: [],
        selected_parent_scene_id: nil,
        back_href: "/games/#{game.id}"
      }.merge(overrides)
    )
  end

  describe "labels and copy" do
    it "uses New Scene wording for the full form" do
      component = build_component(quick: false)
      expect(component.heading).to eq("New Scene")
      expect(component.submit_label).to eq("Create Scene")
      expect(component.quick?).to be(false)
    end

    it "uses Quick Scene wording for the quick form" do
      component = build_component(quick: true)
      expect(component.heading).to eq("Quick Scene")
      expect(component.submit_label).to eq("Create Quick Scene")
      expect(component.quick?).to be(true)
    end

    it "cancel_href returns the supplied back href" do
      expect(build_component(back_href: "/somewhere").cancel_href).to eq("/somewhere")
    end
  end

  describe "form_id" do
    it "gives the full form a stable id for the external submit button" do
      expect(build_component(quick: false).form_id).to eq("new_scene_form")
    end

    it "gives the quick form a distinct id" do
      expect(build_component(quick: true).form_id).to eq("quick_scene_form")
    end
  end

  describe "errors" do
    it "renders no error block on a clean scene" do
      component = build_component
      expect(component.error_messages).to be_empty
      render_inline(component)
      expect(page).to have_no_css(".text-danger")
    end

    it "surfaces validation messages when the scene has errors" do
      scene.errors.add(:base, "Something went wrong")
      component = build_component
      expect(component.error_messages).to include("Something went wrong")
      render_inline(component)
      expect(page).to have_css(".text-danger", text: "Something went wrong")
    end
  end

  describe "#carried_parent_scene_id" do
    it "is the empty string when no parent is selected" do
      expect(build_component(selected_parent_scene_id: nil).carried_parent_scene_id).to eq("")
    end

    it "is the selected parent id when present" do
      expect(build_component(selected_parent_scene_id: "42").carried_parent_scene_id).to eq("42")
    end
  end

  describe "full form rendering" do
    subject(:render_full) do
      render_inline(build_component(
        quick: false,
        players_with_characters: [ ScenePlayerPresenter.new(user, characters: [ character ]) ],
        parent_options: [ [ "The Tavern", 7 ] ],
        selected_character_ids: [ character.id.to_s ]
      ))
    end

    it "renders every full-form field inside the new-scene form" do
      render_full
      expect(page).to have_css("form#new_scene_form")
      expect(page).to have_field("Title (optional — defaults to date/time)")
      expect(page).to have_text("Participants")
      expect(page).to have_text("Seraphina Vex")
      expect(page).to have_select("Parent scene (optional)", with_options: [ "The Tavern" ])
      expect(page).to have_field("Private scene")
      expect(page).to have_field("Scene image (optional)")
    end

    it "pre-checks selected characters" do
      render_full
      expect(page).to have_css("input[name='character_ids[]'][value='#{character.id}'][checked]")
    end

    it "shows a hint for players with no active characters" do
      render_inline(build_component(
        players_with_characters: [ ScenePlayerPresenter.new(user, characters: []) ]
      ))
      expect(page).to have_text("No active characters")
    end
  end

  describe "quick form rendering" do
    subject(:render_quick) do
      render_inline(build_component(
        quick: true,
        selected_character_ids: [ "3", "5" ],
        selected_parent_scene_id: "9"
      ))
    end

    it "renders only the title field inside the quick-scene form" do
      render_quick
      expect(page).to have_css("form#quick_scene_form")
      expect(page).to have_field("Title (optional — defaults to date/time)")
      expect(page).not_to have_text("Participants")
      expect(page).not_to have_field("Private scene")
    end

    it "carries the inherited parent and characters as hidden fields" do
      render_quick
      expect(page).to have_css("input[type='hidden'][name='scene[parent_scene_id]'][value='9']", visible: :all)
      expect(page).to have_css("input[type='hidden'][name='character_ids[]'][value='3']", visible: :all)
      expect(page).to have_css("input[type='hidden'][name='character_ids[]'][value='5']", visible: :all)
    end
  end
end
