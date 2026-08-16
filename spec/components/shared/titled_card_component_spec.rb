require "rails_helper"

RSpec.describe Shared::TitledCardComponent, type: :component do
  it "renders the title as a heading and the markdown body" do
    render_inline(described_class.new(title: "Lore", body: "# Once\n\nupon a time", empty_notice: "empty"))
    expect(page).to have_css("h1", text: "Lore")
    expect(page).to have_text("upon a time")
  end

  it "renders the empty notice when the body is blank" do
    render_inline(described_class.new(title: "Lore", body: "", empty_notice: "Nothing here yet."))
    expect(page).to have_text("Nothing here yet.")
  end
end
