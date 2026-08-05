require "rails_helper"

RSpec.describe Shared::GameHeaderComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "The Sunken Archive") }

  def rendered(**opts)
    render_inline(described_class.new(game: game, title: game.name, **opts))
    page
  end

  it "renders the title" do
    expect(rendered).to have_text("The Sunken Archive")
  end

  it "renders the hamburger wired to open the drawer" do
    expect(rendered).to have_css("button[aria-label='Open navigation'][data-action='click->sidebar#open']")
  end

  it "renders the switch-mode pill tabs" do
    expect(rendered).to have_css("button[data-tab='scenes']")
    expect(rendered).to have_css("button[data-tab='roster']")
    expect(rendered).to have_css("button[data-tab='files']")
    expect(rendered).to have_css("button[data-tab='pages']")
  end

  it "gold-fills the active tab" do
    expect(rendered(active_tab: :roster)).to have_css("button.bg-accent[data-tab='roster']")
  end

  context "as GM" do
    it "shows the crown" do
      expect(rendered(is_gm: true)).to have_css("svg, img", minimum: 1)
      expect(described_class.new(game: game, title: "x", is_gm: true).show_crown?).to be true
    end

    it "shows the gear linking to game settings" do
      allow_any_instance_of(described_class).to receive(:gear_path).and_return("/games/1/player_management")
      expect(rendered(is_gm: true, show_gear: true)).to have_css("a[aria-label='Game settings']")
    end

    it "hides the gear when show_gear is false" do
      expect(described_class.new(game: game, title: "x", is_gm: true, show_gear: false).show_gear?).to be false
    end
  end

  context "as player" do
    it "does not show the crown" do
      expect(described_class.new(game: game, title: "x", is_gm: false).show_crown?).to be false
    end

    it "shows the gear too — the settings page scopes GM-only content itself" do
      expect(described_class.new(game: game, title: "x", is_gm: false, show_gear: true).show_gear?).to be true
    end

    it "still hides the gear when show_gear is false" do
      expect(described_class.new(game: game, title: "x", is_gm: false, show_gear: false).show_gear?).to be false
    end
  end

  it "exposes the four tabs" do
    labels = described_class.new(game: game, title: "x").tabs.map(&:label)
    expect(labels).to eq(%w[Scenes Roster Files Pages])
  end
end
