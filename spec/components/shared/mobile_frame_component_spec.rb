require "rails_helper"

RSpec.describe Shared::MobileFrameComponent, type: :component do
  it "renders body content" do
    render_inline(described_class.new) { "Body here" }
    expect(page).to have_text("Body here")
  end

  it "renders the header slot" do
    render_inline(described_class.new) do |frame|
      frame.with_header { "HEADER" }
      "body"
    end
    expect(page).to have_text("HEADER")
  end

  it "renders the footer slot inside a sticky footer" do
    render_inline(described_class.new) do |frame|
      frame.with_footer { "FOOTER" }
      "body"
    end
    expect(page).to have_css("footer.sticky", text: "FOOTER")
  end

  it "omits the footer element when no footer slot is given" do
    render_inline(described_class.new) { "body" }
    expect(page).not_to have_css("footer")
  end

  it "wraps everything in the app-frame" do
    render_inline(described_class.new) { "body" }
    expect(page).to have_css("div.app-frame .app-body", text: "body")
  end
end
