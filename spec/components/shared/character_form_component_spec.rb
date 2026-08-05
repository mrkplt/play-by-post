require "rails_helper"

RSpec.describe Shared::CharacterFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:new_character) { game.characters.new }
  let(:existing_character) { build_stubbed(:character, game: game, name: "Thornwall") }

  def build_component(**overrides)
    described_class.new(
      **{
        game: game,
        character: new_character,
        users: [],
        new_record: true,
        can_assign_owner: false,
        archived: false,
        back_href: "/games/#{game.id}"
      }.merge(overrides)
    )
  end

  describe "mode-driven copy" do
    it "uses New Character wording for a new record" do
      component = build_component(new_record: true)
      expect(component.submit_label).to eq("Create Character")
      expect(component.content_label).to eq("Sheet (optional, markdown supported)")
    end

    it "uses edit wording for an existing record" do
      component = build_component(character: existing_character, new_record: false)
      expect(component.submit_label).to eq("Save")
      expect(component.content_label).to eq("Sheet (markdown supported)")
    end

    it "exposes the supplied back href" do
      expect(build_component(back_href: "/somewhere").back_href).to eq("/somewhere")
    end
  end

  describe "section visibility flags" do
    it "shows the owner selector only when creating with assign permission" do
      expect(build_component(new_record: true, can_assign_owner: true).owner_select?).to be(true)
      expect(build_component(new_record: true, can_assign_owner: false).owner_select?).to be(false)
      expect(build_component(new_record: false, can_assign_owner: true).owner_select?).to be(false)
    end

    it "shows the visibility toggle only when editing" do
      expect(build_component(new_record: false).visibility_toggle?).to be(true)
      expect(build_component(new_record: true).visibility_toggle?).to be(false)
    end

    it "shows the archive section only when editing with assign permission" do
      expect(build_component(new_record: false, can_assign_owner: true).archive_section?).to be(true)
      expect(build_component(new_record: false, can_assign_owner: false).archive_section?).to be(false)
      expect(build_component(new_record: true, can_assign_owner: true).archive_section?).to be(false)
    end

    it "reflects the archived flag" do
      expect(build_component(archived: true).archived?).to be(true)
      expect(build_component(archived: false).archived?).to be(false)
    end
  end

  describe "#owner_options" do
    it "uses display name when present and falls back to email otherwise" do
      named = build_stubbed(:user, email: "elf@example.com")
      allow(named).to receive(:display_name).and_return("Elrond")
      nameless = build_stubbed(:user, email: "orc@example.com")
      allow(nameless).to receive(:display_name).and_return(nil)

      options = build_component(users: [ named, nameless ]).owner_options
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
    it "renders the name field, markdown toolbar, sheet editor and submit control" do
      render_inline(build_component(new_record: true))
      expect(page).to have_field("Name")
      expect(page).to have_css("div[role='toolbar'][aria-label='Markdown formatting']")
      expect(page).to have_css("textarea.markdown-editor[data-markdown-toolbar-target='input']")
      expect(page).to have_button("Create Character")
      expect(page).to have_link("Cancel", href: "/games/#{game.id}")
    end

    it "omits the owner selector, visibility toggle and archive action" do
      render_inline(build_component(new_record: true, can_assign_owner: false))
      expect(page).not_to have_field("Player")
      expect(page).not_to have_field("Hide from other players")
      expect(page).not_to have_button("Archive character")
    end

    it "renders the owner selector for a GM creating on someone's behalf" do
      user = build_stubbed(:user, email: "player@example.com")
      allow(user).to receive(:display_name).and_return("Aria")
      render_inline(build_component(new_record: true, can_assign_owner: true, users: [ user ]))
      expect(page).to have_select("Player", with_options: [ "Aria" ])
    end
  end

  describe "edit-character rendering" do
    it "renders the visibility toggle and an archive action for a GM" do
      render_inline(build_component(character: existing_character, new_record: false, can_assign_owner: true, archived: false))
      expect(page).to have_field("Hide from other players")
      expect(page).to have_button("Archive character")
      expect(page).to have_button("Save")
    end

    it "renders a restore action when the character is archived" do
      render_inline(build_component(character: existing_character, new_record: false, can_assign_owner: true, archived: true))
      expect(page).to have_button("Restore character")
      expect(page).not_to have_button("Archive character")
    end

    it "hides the archive action from a player editing their own sheet" do
      render_inline(build_component(character: existing_character, new_record: false, can_assign_owner: false))
      expect(page).to have_field("Hide from other players")
      expect(page).not_to have_button("Archive character")
      expect(page).not_to have_button("Restore character")
    end
  end
end
