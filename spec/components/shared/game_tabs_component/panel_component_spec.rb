require "rails_helper"

RSpec.describe Shared::GameTabsComponent::PanelComponent, type: :component do
  it "renders a game-tabs panel section addressed by name" do
    render_inline(described_class.new(name: "roster")) { "Roster".html_safe }
    expect(page).to have_css(
      "section[data-game-tabs-target='panel'][data-panel='roster']", visible: :all
    )
  end

  it "renders the block content inside the panel" do
    render_inline(described_class.new(name: "files")) { "File list".html_safe }
    expect(page).to have_css("section[data-panel='files']", text: "File list", visible: :all)
  end

  it "hides a panel by default" do
    render_inline(described_class.new(name: "roster")) { "Roster".html_safe }
    expect(page).to have_css("section[data-panel='roster'][hidden]", visible: :all)
  end

  it "reports hidden? true for a hidden panel" do
    expect(described_class.new(name: "roster").hidden?).to be(true)
  end

  it "shows a :shown panel (no hidden attribute)" do
    render_inline(described_class.new(name: "scenes", visibility: :shown)) { "Scenes".html_safe }
    expect(page).to have_css("section[data-panel='scenes']")
    expect(page).to have_no_css("section[data-panel='scenes'][hidden]", visible: :all)
  end

  it "reports hidden? false for a :shown panel" do
    expect(described_class.new(name: "scenes", visibility: :shown).hidden?).to be(false)
  end

  it "rejects an unknown visibility" do
    expect { described_class.new(name: "x", visibility: :maybe) }
      .to raise_error(ArgumentError, /Unknown visibility/)
  end
end
