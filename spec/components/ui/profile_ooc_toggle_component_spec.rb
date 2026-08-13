require "rails_helper"

RSpec.describe Ui::ProfileOocToggleComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders the toggle in the off state" do
    expect(rendered(hide_ooc: false, toggle_url: "/profile/toggle_hide_ooc"))
      .to have_css("[role='switch'][aria-checked='false']")
  end

  it "renders the toggle in the on state" do
    expect(rendered(hide_ooc: true, toggle_url: "/profile/toggle_hide_ooc"))
      .to have_css("[role='switch'][aria-checked='true']")
  end

  it "renders the toggle endpoint and accessible label" do
    view = rendered(hide_ooc: false, toggle_url: "/profile/toggle_hide_ooc")

    expect(view).to have_css("[data-ooc-filter-toggle-url-value='/profile/toggle_hide_ooc']")
    expect(view).to have_css("button[aria-label='Hide OOC posts by default']")
  end

  it "uses the show label when OOC posts are hidden" do
    expect(rendered(hide_ooc: true, toggle_url: "/profile/toggle_hide_ooc"))
      .to have_css("button[aria-label='Show OOC posts by default']")
  end
end
