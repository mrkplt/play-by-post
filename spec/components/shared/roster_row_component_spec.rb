require "rails_helper"

RSpec.describe Shared::RosterRowComponent, type: :component do
  def rendered(row: {}, **opts, &block)
    defaults = { name: "Vex Marrowgate", subtitle: "Played by Dana" }
    render_inline(described_class.new(row: defaults.merge(row), **opts), &block)
    page
  end

  it "renders the name and subtitle" do
    r = rendered
    expect(r).to have_text("Vex Marrowgate")
    expect(r).to have_text("Played by Dana")
  end

  it "renders the avatar monogram" do
    expect(rendered).to have_css("span", text: "V")
  end

  it "renders trailing content" do
    expect(rendered { "Removed" }).to have_text("Removed")
  end

  it "shows a crown when flagged" do
    expect(rendered(row: { crown: true })).to have_css("svg, img", minimum: 1)
  end

  it "does not show a crown by default" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }).crown?).to be false
  end

  it "is active by default" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }).active?).to be true
  end

  it "dims an inactive (removed/banned) row" do
    expect(rendered(row: { active: false })).to have_css("div.opacity-70")
  end

  it "defaults to the default colour variant" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }).variant).to eq(:default)
  end

  it "carries the blue variant when given" do
    expect(described_class.new(row: { name: "x", subtitle: "y", variant: :blue }).variant).to eq(:blue)
  end

  it "keeps a divider unless last" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }).row_classes).to include("border-b")
  end

  it "drops the divider on the last row" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }, position: :last).row_classes).not_to include("border-b")
  end

  it "builds exact default row classes" do
    expect(described_class.new(row: { name: "x", subtitle: "y" }).row_classes)
      .to eq("flex items-center gap-2.5 p-[10px_12px] border-b border-card-divider")
  end

  it "builds exact last inactive row classes" do
    expect(described_class.new(row: { name: "x", subtitle: "y", active: false }, position: :last).row_classes)
      .to eq("flex items-center gap-2.5 p-[10px_12px] opacity-70")
  end

  it "rejects an unknown position" do
    expect { described_class.new(row: { name: "x", subtitle: "y" }, position: :unknown) }
      .to raise_error(ArgumentError, /Unknown position/)
  end
end
