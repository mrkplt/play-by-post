require "rails_helper"

RSpec.describe Ui::PillTabsComponent, type: :component do
  let(:tabs) do
    [
      Ui::PillTabsComponent::Tab.new(label: "Scenes", href: "/games/1"),
      Ui::PillTabsComponent::Tab.new(label: "Roster", href: "/games/1/roster"),
      Ui::PillTabsComponent::Tab.new(label: "Files", href: "/games/1/game_files")
    ]
  end

  let(:panel_tabs) do
    [
      Ui::PillTabsComponent::Tab.new(label: "Scenes", panel: :scenes),
      Ui::PillTabsComponent::Tab.new(label: "Roster", panel: :roster),
      Ui::PillTabsComponent::Tab.new(label: "Files", panel: :files)
    ]
  end

  def rendered(active:)
    render_inline(described_class.new(tabs: tabs, active: active))
    page
  end

  def rendered_switch(active:)
    render_inline(described_class.new(tabs: panel_tabs, active: active, mode: :switch))
    page
  end

  it "renders every tab as a link in link mode" do
    expect(rendered(active: :scenes)).to have_css("a", count: 3)
  end

  it "links to each tab's href" do
    expect(rendered(active: :scenes)).to have_css("a[href='/games/1/roster']", text: "Roster")
  end

  it "renders buttons (not links) in switch mode" do
    expect(rendered_switch(active: :scenes)).to have_css("button", count: 3)
  end

  it "does not render anchors in switch mode" do
    expect(rendered_switch(active: :scenes)).not_to have_css("a")
  end

  it "tags each switch button with its panel and a click action" do
    expect(rendered_switch(active: :scenes))
      .to have_css("button[data-tab='roster'][data-action='click->game-tabs#switch']", text: "Roster")
  end

  it "reports switch? true only for switch mode" do
    expect(described_class.new(tabs: panel_tabs, active: :scenes, mode: :switch).switch?).to be true
    expect(described_class.new(tabs: tabs, active: :scenes).switch?).to be false
  end

  it "exposes the panel name for a switch tab" do
    expect(described_class.new(tabs: panel_tabs, active: :scenes, mode: :switch).panel_name(panel_tabs.last)).to eq("files")
  end

  it "gold-fills the active tab" do
    expect(rendered(active: :roster)).to have_css("a.bg-accent.text-accent-ink", text: "Roster")
  end

  it "mutes inactive tabs" do
    expect(rendered(active: :roster)).to have_css("a.bg-pill-idle", text: "Scenes")
  end

  it "marks the active tab with aria-current=page" do
    expect(rendered(active: :files)).to have_css("a[aria-current='page']", text: "Files")
  end

  it "does not mark inactive tabs as current" do
    expect(rendered(active: :files)).not_to have_css("a[aria-current='page']", text: "Scenes")
  end

  it "matches active case-insensitively against the label" do
    expect(described_class.new(tabs: tabs, active: :scenes).active?(tabs.first)).to be true
  end

  it "reports non-active tabs as not active" do
    expect(described_class.new(tabs: tabs, active: :scenes).active?(tabs.last)).to be false
  end

  it "builds the exact active tab class string" do
    c = described_class.new(tabs: tabs, active: :scenes)
    expect(c.tab_classes(tabs.first))
      .to eq("#{Ui::PillTabsComponent::BASE} #{Ui::PillTabsComponent::ACTIVE}")
  end

  it "builds the exact idle tab class string" do
    c = described_class.new(tabs: tabs, active: :scenes)
    expect(c.tab_classes(tabs.last))
      .to eq("#{Ui::PillTabsComponent::BASE} #{Ui::PillTabsComponent::IDLE}")
  end

  it "returns 'page' as aria_current for the active tab and nil otherwise" do
    c = described_class.new(tabs: tabs, active: :scenes)
    expect(c.aria_current(tabs.first)).to eq("page")
    expect(c.aria_current(tabs.last)).to be_nil
  end
end
