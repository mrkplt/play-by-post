require "rails_helper"

RSpec.describe Shared::StatusBadgeRowComponent, type: :component do
  it "renders nothing when the badge list is empty" do
    render_inline(described_class.new(badges: []))
    expect(page).to have_no_css("div")
  end

  it "reports any? false for an empty list" do
    expect(described_class.new(badges: []).any?).to be(false)
  end

  it "renders a single badge with its label and variant" do
    render_inline(described_class.new(badges: [ { label: "Private", variant: :yellow } ]))
    expect(page).to have_css("span", text: "Private")
  end

  it "renders multiple badges in order" do
    render_inline(described_class.new(badges: [
      { label: "Private", variant: :yellow },
      { label: "Resolved", variant: :gray }
    ]))
    labels = page.native.css("span").map(&:text)
    expect(labels).to eq([ "Private", "Resolved" ])
  end

  it "reports any? true when badges are present" do
    expect(described_class.new(badges: [ { label: "Private", variant: :yellow } ]).any?).to be(true)
  end
end
