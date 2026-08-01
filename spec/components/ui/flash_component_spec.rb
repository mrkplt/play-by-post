require "rails_helper"

RSpec.describe Ui::FlashComponent, type: :component do
  it "renders nothing when both are blank" do
    render_inline(described_class.new)
    expect(page).not_to have_css("div")
  end

  it "renders the notice" do
    render_inline(described_class.new(notice: "Saved."))
    expect(page).to have_css("p.bg-green-100", text: "Saved.")
  end

  it "renders the alert" do
    render_inline(described_class.new(alert: "Nope."))
    expect(page).to have_css("p.bg-red-50", text: "Nope.")
  end

  it "does not render a notice paragraph when only an alert is present" do
    render_inline(described_class.new(alert: "Nope."))
    expect(page).not_to have_css("p.bg-green-100")
  end

  it "does not render an alert paragraph when only a notice is present" do
    render_inline(described_class.new(notice: "Saved."))
    expect(page).not_to have_css("p.bg-red-50")
  end

  it "reports any? correctly" do
    expect(described_class.new.any?).to be false
    expect(described_class.new(notice: "x").any?).to be true
    expect(described_class.new(alert: "y").any?).to be true
    expect(described_class.new(notice: "", alert: "").any?).to be false
  end
end
