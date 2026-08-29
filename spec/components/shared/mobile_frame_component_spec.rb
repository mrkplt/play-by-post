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

  it "renders the footer slot pinned as a non-shrinking last child of the frame" do
    render_inline(described_class.new) do |frame|
      frame.with_footer { "FOOTER" }
      "body"
    end
    # The footer is a shrink-0 sibling of the scrolling body, not `sticky`:
    # `sticky` would be clipped by the frame's overflow-hidden.
    expect(page).to have_css("div.app-frame > footer.shrink-0", text: "FOOTER")
    expect(page).not_to have_css("footer.sticky")
  end

  it "omits the footer element when no footer slot is given" do
    render_inline(described_class.new) { "body" }
    expect(page).not_to have_css("footer")
  end

  it "wraps everything in the app-frame with the body as the content region" do
    render_inline(described_class.new) { "body" }
    # `.app-frame`/`.app-body` carry the flex-column + scroll-containment styling
    # (see sidebar_component.css); the footer stays in view because the body is
    # the sole scroll region. The runtime geometry of that is asserted in
    # spec/system/frame_footer_action_spec.rb.
    expect(page).to have_css("div.app-frame > .app-body", text: "body")
  end
end
