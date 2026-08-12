require "rails_helper"

RSpec.describe Ui::AvatarComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders the uppercased first initial" do
    expect(rendered(name: "vex")).to have_css("span", text: "V")
  end

  it "uses only the first character" do
    expect(described_class.new(name: "Brother Ilio").initial).to eq("B")
  end

  it "strips leading whitespace before taking the initial" do
    expect(described_class.new(name: "  dana").initial).to eq("D")
  end

  it "returns empty string for a blank name" do
    expect(described_class.new(name: "").initial).to eq("")
  end

  it "applies gold tone by default" do
    expect(rendered(name: "Vex")).to have_css("span.bg-accent.text-accent-ink")
  end

  it "applies dark tone" do
    expect(rendered(name: "GM", tone: :dark)).to have_css("span.bg-pill-idle")
  end

  it "applies muted tone" do
    expect(rendered(name: "Kess", tone: :muted)).to have_css("span.bg-avatar-muted")
  end

  it "applies blue tone" do
    expect(rendered(name: "Sera", tone: :blue)).to have_css("span.bg-avatar-blue")
  end

  it "applies lg size" do
    expect(rendered(name: "Vex", size: :lg)).to have_css("span.w-10.h-10")
  end

  it "applies sm size" do
    expect(rendered(name: "Vex", size: :sm)).to have_css("span.w-\\[26px\\]")
  end

  it "defaults to md size" do
    expect(rendered(name: "Vex")).to have_css("span.w-7.h-7")
  end

  it "is aria-hidden" do
    expect(rendered(name: "Vex")).to have_css("span[aria-hidden='true']")
  end

  it "composes classes from BASE + size + tone in order" do
    c = described_class.new(name: "Vex", tone: :gold, size: :lg)
    expect(c.classes).to eq(
      "#{Ui::AvatarComponent::BASE} #{Ui::AvatarComponent::SIZES.fetch(:lg)} #{Ui::AvatarComponent::TONES.fetch(:gold)}"
    )
  end

  it "keeps the initial as a String even for a blank name" do
    expect(described_class.new(name: "").initial).to be_a(String).and eq("")
  end

  it "does not just lstrip — trailing whitespace with a leading char stays" do
    expect(described_class.new(name: " a ").initial).to eq("A")
  end
end
