require "rails_helper"

RSpec.describe Shared::HeaderComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders the title" do
    expect(rendered(title: "Profile")).to have_text("Profile")
  end

  it "always renders the hamburger wired to open the drawer" do
    expect(rendered(title: "Profile"))
      .to have_css("button[aria-label='Open navigation'][data-action='click->sidebar#open']")
  end

  it "accents the title when requested" do
    expect(rendered(title: "Your Games", accent_title: true)).to have_css("h1.text-accent")
  end

  it "uses white title by default" do
    expect(rendered(title: "Profile")).to have_css("h1.text-white")
  end

  context "crown" do
    it "renders when crown: true" do
      expect(rendered(title: "Game", crown: true)).to have_css("svg, img", minimum: 1)
    end

    it "does not render when crown: false" do
      expect(described_class.new(title: "Game", crown: false).crown?).to be false
    end
  end

  context "gear" do
    it "renders a settings link when gear: is given" do
      expect(rendered(title: "Game", gear: "/games/1/player_management"))
        .to have_css("a[aria-label='Game settings'][href='/games/1/player_management']")
    end

    it "omits the gear when gear: is nil" do
      expect(rendered(title: "Game")).not_to have_css("a[aria-label='Game settings']")
    end
  end

  context "breadcrumbs" do
    it "renders the passed-in breadcrumbs component" do
      game = build_stubbed(:game, name: "The Sunken Archive")
      expect(rendered(title: "Roster", breadcrumbs: Shared::BreadcrumbsComponent.new(game: game)))
        .to have_link("The Sunken Archive")
    end

    it "omits breadcrumbs when nil" do
      expect(rendered(title: "New Game")).not_to have_css("nav[aria-label='Breadcrumb']")
    end
  end

  context "secondary_nav" do
    it "renders the passed-in secondary nav component" do
      game = build_stubbed(:game)
      nav = Shared::GameNavComponent.new(game: game, active_tab: :roster, mode: :switch)
      expect(rendered(title: "Game", secondary_nav: nav)).to have_css("button[data-tab='roster']")
    end

    it "omits secondary nav when nil" do
      expect(rendered(title: "Profile")).not_to have_css("[data-tab]")
    end
  end
end
