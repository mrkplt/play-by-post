require "rails_helper"

RSpec.describe Ui::SectionLabelComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders the content block" do
    expect(rendered { "Active Scenes" }).to have_css("div", text: "Active Scenes")
  end

  it "applies the uppercase muted base classes" do
    expect(rendered { "Characters" }).to have_css("div.uppercase.text-muted.font-bold")
  end

  it "returns only the base classes when no html_class given" do
    expect(described_class.new.classes).to eq(Ui::SectionLabelComponent::BASE)
  end

  it "appends an extra html_class" do
    expect(described_class.new(html_class: "mt-4").classes).to eq("#{Ui::SectionLabelComponent::BASE} mt-4")
  end

  it "renders the extra html_class in the DOM" do
    expect(rendered(html_class: "mt-4") { "X" }).to have_css("div.mt-4")
  end
end
