require "rails_helper"

RSpec.describe Ui::ToggleSwitchComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "defaults to off" do
    expect(described_class.new.on?).to be false
  end

  it "reports on? true when on" do
    expect(described_class.new(on: true).on?).to be true
  end

  it "uses the idle track colour token when off" do
    expect(rendered).to have_css("span.bg-pill-idle")
  end

  it "uses the gold track colour when on" do
    expect(rendered(on: true)).to have_css("span.bg-accent")
  end

  it "positions the thumb left when off" do
    expect(rendered).to have_css("span.left-0\\.5")
  end

  it "positions the thumb right when on" do
    expect(rendered(on: true)).to have_css("span.right-0\\.5")
  end

  it "sets aria-checked to match state when on" do
    expect(rendered(on: true)).to have_css("span[role='switch'][aria-checked='true']")
  end

  it "sets aria-checked false when off" do
    expect(rendered).to have_css("span[role='switch'][aria-checked='false']")
  end

  it "appends an extra html_class to the track" do
    expect(rendered(html_class: "ml-2")).to have_css("span.ml-2")
  end

  it "builds the exact off track class string" do
    expect(described_class.new(on: false).track_classes)
      .to eq("inline-block w-8 h-[18px] rounded-[9px] relative transition-colors duration-150 flex-shrink-0 bg-pill-idle")
  end

  it "builds the exact on track class string" do
    expect(described_class.new(on: true).track_classes)
      .to eq("inline-block w-8 h-[18px] rounded-[9px] relative transition-colors duration-150 flex-shrink-0 bg-accent")
  end

  it "drops an empty html_class from the track join" do
    expect(described_class.new(on: false).track_classes).not_to end_with(" ")
  end

  it "builds the exact off thumb class string" do
    expect(described_class.new(on: false).thumb_classes)
      .to eq("w-[14px] h-[14px] rounded-full bg-white absolute top-0.5 transition-all duration-150 left-0.5")
  end

  it "builds the exact on thumb class string" do
    expect(described_class.new(on: true).thumb_classes)
      .to eq("w-[14px] h-[14px] rounded-full bg-white absolute top-0.5 transition-all duration-150 right-0.5")
  end
end
