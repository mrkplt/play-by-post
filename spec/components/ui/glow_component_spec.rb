require "rails_helper"

RSpec.describe Ui::GlowComponent, type: :component do
  def rendered(state: :idle, &block)
    render_inline(described_class.new(state: state), &block)
    page
  end

  it "renders without glow class when idle by default" do
    expect(rendered { "content" }).not_to have_css(".ui-glow")
  end

  it "renders with ui-glow class when glowing" do
    expect(rendered(state: :glowing) { "content" }).to have_css("div.ui-glow")
  end

  it "renders the content block" do
    expect(rendered(state: :idle) { "inner content" }).to have_text("inner content")
  end

  it "active? returns true when glowing" do
    expect(described_class.new(state: :glowing).active?).to be true
  end

  it "active? returns false when idle" do
    expect(described_class.new(state: :idle).active?).to be false
  end

  it "wrapper_class returns ui-glow when glowing" do
    expect(described_class.new(state: :glowing).wrapper_class).to eq("ui-glow")
  end

  it "wrapper_class returns empty string when idle" do
    expect(described_class.new(state: :idle).wrapper_class).to eq("")
  end

  it "wrapper_html_attributes includes data-new-activity when glowing" do
    expect(described_class.new(state: :glowing).wrapper_html_attributes).to include(data: { new_activity: true })
  end

  it "wrapper_html_attributes omits data key when idle" do
    expect(described_class.new(state: :idle).wrapper_html_attributes).not_to have_key(:data)
  end

  it "renders data-new-activity attribute on wrapper when glowing" do
    expect(rendered(state: :glowing) { "content" }).to have_css("div[data-new-activity='true']")
  end

  it "does not render data-new-activity attribute on wrapper when idle" do
    expect(rendered { "content" }).not_to have_css("[data-new-activity]")
  end

  it "rejects an unknown state" do
    expect { described_class.new(state: :unknown) }.to raise_error(ArgumentError, /Unknown state/)
  end
end
