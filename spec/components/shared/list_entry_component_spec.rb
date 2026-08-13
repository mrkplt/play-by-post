require "rails_helper"

RSpec.describe Shared::ListEntryComponent, type: :component do
  def row(title:, href:, controls: nil)
    { title: title, href: href, controls: controls }
  end

  def build_component(**overrides)
    described_class.new(**{
      rows: [ row(title: "Alpha", href: "/alpha"), row(title: "Beta", href: "/beta") ],
      empty_text: "Nothing here yet."
    }.merge(overrides))
  end

  describe "#row_classes" do
    it "gives the first row no divider" do
      expect(build_component.row_classes(0)).to eq(described_class::ROW_BASE)
    end

    it "gives later rows a top divider" do
      expect(build_component.row_classes(1)).to eq("#{described_class::ROW_BASE} border-t border-card-divider")
    end
  end

  describe "#any_rows?" do
    it "is true when rows are present" do
      expect(build_component.any_rows?).to be(true)
    end

    it "is false when there are no rows" do
      expect(build_component(rows: []).any_rows?).to be(false)
    end
  end

  describe "rendering" do
    it "links each row's title to its href" do
      render_inline(build_component)
      expect(page).to have_link("Alpha", href: "/alpha")
      expect(page).to have_link("Beta", href: "/beta")
    end

    it "renders the rows inside a single grouped card" do
      render_inline(build_component)
      expect(page).to have_css("div.bg-card.border.rounded-card.overflow-hidden", count: 1)
    end

    it "divides every row but the first" do
      render_inline(build_component)
      expect(page).to have_css(".border-t.border-card-divider", count: 1)
    end

    it "renders the empty text and no card when there are no rows" do
      render_inline(build_component(rows: []))
      expect(page).to have_text("Nothing here yet.")
      expect(page).to have_no_css("div.bg-card.rounded-card")
    end

    it "renders a row's controls after its title" do
      controls = Ui::BadgeComponent.new(variant: :gray)
      render_inline(build_component(rows: [ row(title: "Alpha", href: "/alpha", controls: controls) ]))
      expect(page).to have_css("div.flex-shrink-0")
    end

    it "omits the controls wrapper for a row without controls" do
      render_inline(build_component(rows: [ row(title: "Alpha", href: "/alpha") ]))
      expect(page).to have_no_css("div.flex-shrink-0")
    end

    it "renders controls only on the rows that carry them" do
      render_inline(build_component(rows: [
        row(title: "Alpha", href: "/alpha", controls: Ui::BadgeComponent.new(variant: :gray)),
        row(title: "Beta", href: "/beta")
      ]))
      expect(page).to have_css("div.flex-shrink-0", count: 1)
    end

    it "truncates a long title rather than wrapping the row" do
      render_inline(build_component(rows: [ row(title: "A" * 200, href: "/alpha") ]))
      expect(page).to have_css("span.truncate")
    end
  end
end
