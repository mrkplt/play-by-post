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
end
