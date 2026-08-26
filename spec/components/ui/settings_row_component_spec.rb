require "rails_helper"

RSpec.describe Ui::SettingsRowComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders the label" do
    expect(rendered(label: "Display Name") { "Edit" }).to have_css("span", text: "Display Name")
  end

  it "renders the control block on the right" do
    expect(rendered(label: "Export") { "Request" }).to have_text("Request")
  end

  it "renders the sub-label when given" do
    expect(rendered(label: "RSS Token", sub: "Revoke to invalidate") { "Rotate" })
      .to have_css("span", text: "Revoke to invalidate")
  end

  it "omits the sub-label when not given" do
    expect(rendered(label: "Display Name") { "Edit" }).not_to have_css("span.text-muted-2")
  end

  it "includes a bottom divider by default" do
    expect(rendered(label: "A") { "x" }).to have_css("div.border-b.border-card-divider")
  end

  it "omits the divider on the last row" do
    expect(rendered(label: "A", position: :last) { "x" }).not_to have_css("div.border-b")
  end

  it "builds the exact non-last row class string" do
    expect(described_class.new(label: "A").row_classes)
      .to eq("flex justify-between items-center py-3 gap-2.5 border-b border-card-divider")
  end

  it "builds the exact last row class string" do
    expect(described_class.new(label: "A", position: :last).row_classes)
      .to eq("flex justify-between items-center py-3 gap-2.5")
  end

  it "rejects an unknown position" do
    expect { described_class.new(label: "A", position: :unknown) }.to raise_error(ArgumentError, /Unknown position/)
  end

  it "keeps the control cluster fixed-width by default" do
    expect(described_class.new(label: "A").control_classes)
      .to eq("flex items-center gap-3 flex-shrink-0")
  end

  it "lets the control cluster shrink when asked" do
    expect(described_class.new(label: "A", control: :shrink).control_classes)
      .to eq("flex items-center gap-3 min-w-0")
  end

  it "rejects an unknown control layout" do
    expect { described_class.new(label: "A", control: :unknown) }.to raise_error(KeyError)
  end
end
