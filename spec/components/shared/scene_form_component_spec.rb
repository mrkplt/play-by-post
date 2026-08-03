require "rails_helper"

RSpec.describe Shared::SceneFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { game.scenes.new }
  let(:user) { build_stubbed(:user, :with_profile) }
  let(:character) { build_stubbed(:character, name: "Seraphina Vex", user: user) }

  def build_component(**overrides)
    described_class.new(
      **{
        game: game,
        scene: scene,
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

  describe "errors" do
    it "reports no errors on a clean scene" do
      component = build_component
      expect(component.errors?).to be(false)
      expect(component.error_messages).to be_empty
    end

    it "surfaces validation messages when the scene has errors" do
      scene.errors.add(:base, "Something went wrong")
      component = build_component
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Something went wrong")
    end
  end

  describe "#character_checked?" do
    it "is true when the character id is in the selected set" do
      component = build_component(selected_character_ids: [ character.id.to_s ])
      expect(component.character_checked?(character)).to be(true)
    end

    it "is false when the character id is not selected" do
      component = build_component(selected_character_ids: [ "999" ])
      expect(component.character_checked?(character)).to be(false)
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
        players_with_characters: [ [ UserPresenter.new(user), [ character ] ] ],
        parent_options: [ [ "The Tavern", 7 ] ],
        selected_character_ids: [ character.id.to_s ]
      ))
    end

    it "renders every full-form field and the submit/cancel controls" do
      render_full
      expect(page).to have_field("Title (optional — defaults to date/time)")
      expect(page).to have_text("Participants")
      expect(page).to have_text("Seraphina Vex")
      expect(page).to have_select("Parent scene (optional)", with_options: [ "The Tavern" ])
      expect(page).to have_field("Private scene")
      expect(page).to have_field("Scene image (optional)")
      expect(page).to have_button("Create Scene")
      expect(page).to have_link("Cancel", href: "/games/#{game.id}")
    end

    it "pre-checks selected characters" do
      render_full
      expect(page).to have_css("input[name='character_ids[]'][value='#{character.id}'][checked]")
    end

    it "shows a hint for players with no active characters" do
      render_inline(build_component(
        players_with_characters: [ [ UserPresenter.new(user), [] ] ]
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

    it "renders only the title field plus the quick submit control" do
      render_quick
      expect(page).to have_field("Title (optional — defaults to date/time)")
      expect(page).to have_button("Create Quick Scene")
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
