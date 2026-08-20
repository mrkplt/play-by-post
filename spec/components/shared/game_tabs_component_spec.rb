require "rails_helper"

RSpec.describe Shared::GameTabsComponent, type: :component do
  it "mounts the game-tabs controller on the wrapper" do
    render_inline(described_class.new) { "Panels".html_safe }
    expect(page).to have_css("div[data-controller='game-tabs']")
  end

  it "renders the block content (the frame and panels) inside the wrapper" do
    render_inline(described_class.new) { "Frame content".html_safe }
    expect(page).to have_css("div[data-controller='game-tabs']", text: "Frame content")
  end
end
