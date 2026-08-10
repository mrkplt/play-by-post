require "rails_helper"

RSpec.describe Shared::ParticipantCheckboxListComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user, :with_profile) }
  let(:character) { build_stubbed(:character, game: game, user: user, name: "Thorin") }

  def build_component(players_with_characters:, selected_character_ids: [], variant: :card)
    described_class.new(
      players_with_characters: players_with_characters,
      selected_character_ids: selected_character_ids,
      variant: variant
    )
  end

  it "always shows the GM auto-include note" do
    render_inline(build_component(players_with_characters: []))
    expect(page).to have_text("The GM is always included automatically.")
  end

  it "lists a player's active characters as checkboxes" do
    render_inline(build_component(players_with_characters: [ [ UserPresenter.new(user), [ character ] ] ]))
    expect(page).to have_field("character_ids[]", type: "checkbox")
    expect(page).to have_text("Thorin")
  end

  it "shows a no-active-characters note for a player with none" do
    render_inline(build_component(players_with_characters: [ [ UserPresenter.new(user), [] ] ]))
    expect(page).to have_text("No active characters")
  end

  describe "checked state" do
    it "checks a character present in selected_character_ids" do
      render_inline(build_component(
        players_with_characters: [ [ UserPresenter.new(user), [ character ] ] ],
        selected_character_ids: [ character.id.to_s ]
      ))
      expect(page).to have_field("character_ids[]", checked: true)
    end

    it "leaves an unselected character unchecked" do
      render_inline(build_component(
        players_with_characters: [ [ UserPresenter.new(user), [ character ] ] ],
        selected_character_ids: []
      ))
      expect(page).to have_field("character_ids[]", checked: false)
    end
  end

  describe "variant wrapper" do
    Shared::ParticipantCheckboxListComponent::VARIANTS.each do |variant|
      it "renders the #{variant} variant without error" do
        expect {
          render_inline(build_component(players_with_characters: [], variant: variant))
        }.not_to raise_error
      end
    end

    it "wraps the card variant in the token card container" do
      component = build_component(players_with_characters: [], variant: :card)
      render_inline(component)
      expect(component.wrapper_classes).to include("bg-card")
    end

    it "wraps the simple variant without the card container" do
      component = build_component(players_with_characters: [], variant: :simple)
      render_inline(component)
      expect(component.wrapper_classes).not_to include("bg-card")
    end
  end
end
