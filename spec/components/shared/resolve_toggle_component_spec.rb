require "rails_helper"

RSpec.describe Shared::ResolveToggleComponent, type: :component do
  def rendered
    render_inline(described_class.new(
      quick_scene_path: "/quick",
      new_scene_path: "/new",
      edit_participants_path: "/participants",
      resolve_path: "/resolve"
    ))
    page
  end

  it "mounts the resolve-toggle controller on the wrapper" do
    expect(rendered).to have_css("div[data-controller='resolve-toggle']")
  end

  it "renders the End Scene button wired to the toggle action" do
    expect(rendered).to have_css("[data-action='click->resolve-toggle#toggle']", text: "End Scene")
  end

  it "renders the three navigation actions" do
    expect(rendered).to have_link("Quick Scene", href: "/quick")
    expect(rendered).to have_link("New Scene", href: "/new")
    expect(rendered).to have_link("Edit Participants", href: "/participants")
  end

  it "renders the resolve form targeting the resolve path" do
    expect(rendered).to have_css("form[action='/resolve']", visible: :all)
  end
end
