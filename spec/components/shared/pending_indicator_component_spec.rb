require "rails_helper"

RSpec.describe Shared::PendingIndicatorComponent, type: :component do
  it "renders the spinner beside the message" do
    render_inline(described_class.new(message: "Preparing…"))

    expect(page).to have_text("Preparing…")
    expect(page).to have_css(".animate-spin")
  end

  it "spells the shared waiting-row layout" do
    render_inline(described_class.new(message: "Waiting…"))

    expect(page).to have_css("div.flex.items-center.gap-3.text-muted-2.py-4")
  end

  it "carries caller data attributes on the wrapper so a Stimulus controller can ride the row" do
    render_inline(described_class.new(
      message: "Preparing…",
      data: { controller: "frame-poll", "frame-poll-url-value": "/profile/byok_key" }
    ))

    expect(page).to have_css(
      "[data-controller='frame-poll'][data-frame-poll-url-value='/profile/byok_key']"
    )
  end

  it "renders no data attributes when none are given" do
    render_inline(described_class.new(message: "Waiting…"))

    expect(page).not_to have_css("[data-controller]")
  end
end
