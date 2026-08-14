require "rails_helper"

RSpec.describe Shared::CharacterFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:new_character) { game.characters.new }
  let(:existing_character) { build_stubbed(:character, game: game, name: "Thornwall") }
  let(:archived_character) { build_stubbed(:character, :archived, game: game, name: "Retired") }

  def presenter_for(character, can_assign_owner: false)
    character_policy = instance_double(CharacterPolicy, assign_owner?: can_assign_owner)
    CharacterPresenter.new(character, character_policy: character_policy)
  end

  def build_component(character: new_character, can_assign_owner: false, players: [])
    described_class.new(
      character: presenter_for(character, can_assign_owner: can_assign_owner),
      owner_options: players.map { |user| UserPresenter.new(user).select_option }
    )
  end

  def path(name, *args)
    Rails.application.routes.url_helpers.public_send(name, *args)
  end

  describe "mode derived from the character" do
    it "treats an unpersisted character as a new record" do
      component = build_component(character: new_character)
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Character")
      expect(component.content_label).to eq("Sheet (optional, markdown supported)")
    end

    it "treats a persisted character as an edit" do
      component = build_component(character: existing_character)
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
      expect(component.content_label).to eq("Sheet (markdown supported)")
    end

    it "reflects the character's archived state" do
      expect(build_component(character: archived_character).archived?).to be(true)
      expect(build_component(character: existing_character).archived?).to be(false)
    end
  end

  describe "section visibility" do
    it "shows the owner selector only when creating with assign permission" do
      expect(build_component(character: new_character, can_assign_owner: true).owner_select?).to be(true)
      expect(build_component(character: new_character, can_assign_owner: false).owner_select?).to be(false)
      expect(build_component(character: existing_character, can_assign_owner: true).owner_select?).to be(false)
    end

    it "shows the visibility toggle only when editing" do
      expect(build_component(character: existing_character).visibility_toggle?).to be(true)
      expect(build_component(character: new_character).visibility_toggle?).to be(false)
    end

    it "shows the archive section only when editing with assign permission" do
      expect(build_component(character: existing_character, can_assign_owner: true).archive_section?).to be(true)
      expect(build_component(character: existing_character, can_assign_owner: false).archive_section?).to be(false)
      expect(build_component(character: new_character, can_assign_owner: true).archive_section?).to be(false)
    end
  end

  describe "#owner_options" do
    it "exposes the owner_options it was constructed with" do
      named = build_stubbed(:user, email: "elf@example.com")
      allow(named).to receive(:display_name).and_return("Elrond")
      nameless = build_stubbed(:user, email: "orc@example.com")
      allow(nameless).to receive(:display_name).and_return(nil)

      options = build_component(players: [ named, nameless ]).owner_options
      expect(options).to eq([ [ "Elrond", named.id ], [ "orc@example.com", nameless.id ] ])
    end
  end

  describe "errors" do
    it "reports no errors on a clean character" do
      component = build_component
      expect(component.errors?).to be(false)
      expect(component.error_messages).to be_empty
    end

    it "surfaces validation messages when the character has errors" do
      new_character.errors.add(:name, "can't be blank")
      component = build_component
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Name can't be blank")
    end
  end

  describe "new-character rendering" do
    it "renders the name field, markdown toolbar, sheet editor and a form id for the external submit button" do
      render_inline(build_component(character: new_character))
      expect(page).to have_field("Name")
      expect(page).to have_css("div[role='toolbar'][aria-label='Markdown formatting']")
      expect(page).to have_css("textarea.markdown-editor[data-markdown-toolbar-target='input']")
      expect(page).to have_css("form#new_character_form")
    end

    it "omits the owner selector, visibility toggle and archive action" do
      render_inline(build_component(character: new_character, can_assign_owner: false))
      expect(page).not_to have_field("Player")
      expect(page).not_to have_field("Hide from other players")
      expect(page).not_to have_button("Archive character")
    end

    it "renders the owner selector for a GM creating on someone's behalf" do
      user = build_stubbed(:user, email: "player@example.com")
      allow(user).to receive(:display_name).and_return("Aria")
      render_inline(build_component(character: new_character, can_assign_owner: true, players: [ user ]))
      expect(page).to have_select("Player", with_options: [ "Aria" ])
    end
  end

  describe "edit-character rendering" do
    it "renders the visibility toggle, archive action, and a per-record form id for a GM" do
      render_inline(build_component(character: existing_character, can_assign_owner: true))
      expect(page).to have_field("Hide from other players")
      expect(page).to have_button("Archive character")
      expect(page).to have_css("form#edit_character_#{existing_character.id}_form")
    end

    it "renders a restore action when the character is archived" do
      render_inline(build_component(character: archived_character, can_assign_owner: true))
      expect(page).to have_button("Restore character")
      expect(page).not_to have_button("Archive character")
    end

    it "hides the archive action from a player editing their own sheet" do
      render_inline(build_component(character: existing_character, can_assign_owner: false))
      expect(page).to have_field("Hide from other players")
      expect(page).not_to have_button("Archive character")
      expect(page).not_to have_button("Restore character")
    end
  end
end
