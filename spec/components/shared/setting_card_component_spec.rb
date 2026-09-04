# typed: false

require "rails_helper"

RSpec.describe Shared::SettingCardComponent, type: :component do
  def build_component(title: "AI Scene Summaries", toggle_label: "Enable", toggle_path: "/games/g/toggle")
    described_class.new(title: title, toggle_label: toggle_label, toggle_path: toggle_path)
  end

  it "renders the section label from the title" do
    render_inline(build_component(title: "Player Contributions")) { "body" }
    expect(page).to have_text("Player Contributions")
  end

  it "renders the block body as the status sentence" do
    render_inline(build_component) { "Something is currently on." }
    expect(page).to have_text("Something is currently on.")
  end

  it "renders the flip button with its label and path" do
    render_inline(build_component(toggle_label: "Disable", toggle_path: "/games/g/flip")) { "body" }
    expect(page).to have_button("Disable")
    expect(page).to have_css("form[action='/games/g/flip']")
    expect(page.find("form[action='/games/g/flip']")).to have_field("_method", type: :hidden, with: "patch")
  end
end
