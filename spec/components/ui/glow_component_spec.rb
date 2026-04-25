require "rails_helper"

RSpec.describe Ui::GlowComponent, type: :component do
  def rendered(active: false, &block)
    render_inline(described_class.new(active: active), &block)
    page
  end

  it "renders without glow class when inactive by default" do
    expect(rendered { "content" }).not_to have_css(".ui-glow")
  end

  it "renders with ui-glow class when active" do
    expect(rendered(active: true) { "content" }).to have_css("div.ui-glow")
  end

  it "renders the content block" do
    expect(rendered(active: false) { "inner content" }).to have_text("inner content")
  end

  it "active? returns true when active" do
    expect(described_class.new(active: true).active?).to be true
  end

  it "active? returns false when inactive" do
    expect(described_class.new(active: false).active?).to be false
  end

  it "wrapper_class returns ui-glow when active" do
    expect(described_class.new(active: true).wrapper_class).to eq("ui-glow")
  end

  it "wrapper_class returns empty string when inactive" do
    expect(described_class.new(active: false).wrapper_class).to eq("")
  end

  it "wrapper_html_attributes includes data-new-activity when active" do
    expect(described_class.new(active: true).wrapper_html_attributes).to include(data: { new_activity: true })
  end

  it "wrapper_html_attributes omits data key when inactive" do
    expect(described_class.new(active: false).wrapper_html_attributes).not_to have_key(:data)
  end

  it "renders data-new-activity attribute on wrapper when active" do
    expect(rendered(active: true) { "content" }).to have_css("div[data-new-activity='true']")
  end

  it "does not render data-new-activity attribute on wrapper when inactive" do
    expect(rendered { "content" }).not_to have_css("[data-new-activity]")
  end
end
