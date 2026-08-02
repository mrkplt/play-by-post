require "rails_helper"

RSpec.describe Ui::CardComponent, type: :component do
  def rendered(&block)
    render_inline(described_class.new, &block)
    page
  end

  it "renders the content block" do
    expect(rendered { "Row content" }).to have_text("Row content")
  end

  it "applies the card shell classes" do
    expect(rendered { "X" }).to have_css("div.bg-card.border.border-card-border.rounded-card.px-3\\.5")
  end

  it "exposes the base classes constant" do
    expect(described_class.new.classes).to eq(Ui::CardComponent::BASE)
  end
end
