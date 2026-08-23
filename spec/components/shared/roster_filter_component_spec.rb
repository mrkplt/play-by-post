require "rails_helper"

RSpec.describe Shared::RosterFilterComponent, type: :component do
  def roster(characters: [], inactive: false)
    instance_double(
      GameRosterPresenter,
      roster_characters?: characters.any?,
      roster_characters: characters,
      roster_character_position: :last,
      inactive_characters?: inactive,
      inactive_character_count: inactive ? 2 : 0
    )
  end

  def character(name:, owner:, key:, removed: false)
    instance_double(
      RosterCharacterPresenter,
      character_name: name, owner_name: owner, filter_key: key,
      avatar_tone: :gold, removed?: removed, portrait_url: nil
    )
  end

  it "mounts the roster-filter controller on the wrapper" do
    render_inline(described_class.new(roster: roster, new_character_path: "/new"))
    expect(page).to have_css("div[data-controller='roster-filter']")
  end

  it "renders the search input wired to the filter action" do
    render_inline(described_class.new(roster: roster, new_character_path: "/new"))
    expect(page).to have_css(
      "input[data-roster-filter-target='query'][data-action='input->roster-filter#filter']"
    )
  end

  it "links to the new character path" do
    render_inline(described_class.new(roster: roster, new_character_path: "/games/1/characters/new"))
    expect(page).to have_link("New Character", href: "/games/1/characters/new")
  end

  it "shows the empty state when there are no characters" do
    render_inline(described_class.new(roster: roster, new_character_path: "/new"))
    expect(page).to have_text("No characters yet.")
  end

  it "renders a filter-target row per character with its filter key" do
    chars = [ character(name: "Vex", owner: "Sam", key: "vex sam") ]
    render_inline(described_class.new(roster: roster(characters: chars), new_character_path: "/new"))
    expect(page).to have_css("[data-roster-filter-target='row'][data-roster-name='vex sam']")
    expect(page).to have_text("Vex")
  end

  it "shows the inactive-count note when there are hidden characters" do
    render_inline(described_class.new(roster: roster(inactive: true), new_character_path: "/new"))
    expect(page).to have_text("2 inactive characters hidden")
  end

  it "omits the inactive-count note when none are hidden" do
    render_inline(described_class.new(roster: roster, new_character_path: "/new"))
    expect(page).to have_no_text("inactive character")
  end
end
