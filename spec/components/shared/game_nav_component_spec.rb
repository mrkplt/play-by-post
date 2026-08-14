require "rails_helper"

RSpec.describe Shared::GameNavComponent, type: :component do
  let(:game) { build_stubbed(:game) }

  def game_presenter(can_manage: false)
    GamePresenter.new(game, policy: instance_double(GamePolicy, manage?: can_manage))
  end

  def rendered(can_manage: false, **opts)
    render_inline(described_class.new(game_presenter: game_presenter(can_manage: can_manage), active_tab: :scenes, **opts))
    page
  end

  it "exposes five tabs to a non-GM" do
    component = described_class.new(game_presenter: game_presenter(can_manage: false), active_tab: :scenes)
    render_inline(component)
    expect(component.tabs.map(&:label)).to eq(%w[Scenes Roster Files Pages Links])
  end

  it "adds a Notebook tab for the GM" do
    component = described_class.new(game_presenter: game_presenter(can_manage: true), active_tab: :scenes)
    render_inline(component)
    expect(component.tabs.map(&:label)).to eq(%w[Scenes Roster Files Pages Links Notebook])
  end

  context "switch mode (default)" do
    it "renders buttons that toggle in-page panels" do
      expect(rendered(mode: :switch)).to have_css("button[data-tab='scenes']")
      expect(rendered(mode: :switch)).to have_css("button[data-tab='roster']")
    end

    it "gold-fills the active tab" do
      expect(rendered(active_tab: :roster, mode: :switch)).to have_css("button.bg-accent[data-tab='roster']")
    end
  end

  context "link mode" do
    it "renders anchors for cross-page navigation" do
      expect(rendered(mode: :link)).to have_link("Scenes")
      expect(rendered(mode: :link)).to have_link("Roster")
    end

    it "gold-fills the active tab" do
      expect(rendered(active_tab: :files, mode: :link)).to have_css("a.bg-accent", text: "Files")
    end

    it "links Scenes to the scenes index" do
      expect(rendered(mode: :link)).to have_css("a[href*='/scenes']", text: "Scenes")
    end

    it "links Files to the game files index" do
      expect(rendered(mode: :link)).to have_css("a[href*='/game_files']", text: "Files")
    end

    it "links Links to the game links index" do
      expect(rendered(mode: :link)).to have_css("a[href*='/game_links']", text: "Links")
    end

    it "links Notebook to the notebook index for the GM" do
      expect(rendered(mode: :link, can_manage: true)).to have_css("a[href*='/notebook_entries']", text: "Notebook")
    end

    it "links Roster and Pages back to the game page anchors (no dedicated page)" do
      html = rendered(mode: :link)
      expect(html).to have_css("a[href*='#roster']", text: "Roster")
      expect(html).to have_css("a[href*='#pages']", text: "Pages")
    end
  end
end
