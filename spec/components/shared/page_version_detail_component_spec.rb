require "rails_helper"

RSpec.describe Shared::PageVersionDetailComponent, type: :component do
  let(:editor) { build_stubbed(:user) }

  def build_component(title: "Lore", body: "the tale")
    version = build_stubbed(:page_version, edited_by: editor, title: title, body: body,
                                           created_at: Time.utc(2026, 1, 2, 15, 4))
    described_class.new(version: PageVersionPresenter.new(version))
  end

  it "renders the version's title and body" do
    render_inline(build_component(title: "Ancient Lore", body: "# Once\n\nupon a time"))
    expect(page).to have_css("h1", text: "Ancient Lore")
    expect(page).to have_text("upon a time")
  end

  it "shows the editor and timestamp" do
    render_inline(build_component)
    expect(page).to have_text("Edited by:")
    expect(page).to have_css("time")
  end

  it "shows a placeholder when the version has no body" do
    render_inline(build_component(body: nil))
    expect(page).to have_text("No content in this version.")
  end
end
