require "rails_helper"

RSpec.describe Shared::PageHeaderComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders the title" do
    expect(rendered(title: "Profile")).to have_text("Profile")
  end

  it "renders a hamburger by default wired to open the drawer" do
    expect(rendered(title: "Your Games"))
      .to have_css("button[aria-label='Open navigation'][data-action='click->sidebar#open']")
  end

  it "renders a back link when leading is :back" do
    expect(rendered(title: "Files", leading: :back, back_href: "/games/1"))
      .to have_css("a[href='/games/1']")
  end

  it "reports back? correctly" do
    expect(described_class.new(title: "x", leading: :back, back_href: "/g").back?).to be true
    expect(described_class.new(title: "x").back?).to be false
  end

  it "accents the title when requested" do
    expect(rendered(title: "Your Games", accent_title: true)).to have_css("h1.text-accent")
  end

  it "uses white title by default" do
    expect(rendered(title: "Profile")).to have_css("h1.text-white")
  end
end
