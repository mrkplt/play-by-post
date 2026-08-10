require "rails_helper"

RSpec.describe Shared::ControlRowComponent, type: :component do
  it "renders no label when none is given" do
    render_inline(described_class.new) { "Content" }
    expect(page).to have_no_css("span")
  end

  it "reports label? false when no label is given" do
    expect(described_class.new.label?).to be(false)
  end

  it "renders the given label" do
    render_inline(described_class.new(label: "Participants:")) { "Content" }
    expect(page).to have_css("span", text: "Participants:")
  end

  it "reports label? true when a label is given" do
    expect(described_class.new(label: "Participants:").label?).to be(true)
  end

  it "renders the block content" do
    render_inline(described_class.new) { "A control".html_safe }
    expect(page).to have_text("A control")
  end
end
