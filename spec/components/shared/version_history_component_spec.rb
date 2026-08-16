require "rails_helper"

RSpec.describe Shared::VersionHistoryComponent, type: :component do
  def row(path: "/games/1/pages/x/versions/2", editor: "Gandalf the Grey")
    described_class::Row.new(
      path: path, timestamp: "2026-01-02T15:04:00Z",
      formatted: "Jan 2, 2026 3:04 PM", editor: editor
    )
  end

  describe "#version_count" do
    it "counts the rows" do
      expect(described_class.new(rows: [ row ]).version_count).to eq(1)
      expect(described_class.new(rows: []).version_count).to eq(0)
    end
  end

  describe "rendering" do
    it "titles the disclosure with the count and renders a linked row per version" do
      render_inline(described_class.new(rows: [ row(path: "/v/2", editor: "Gandalf") ]))

      expect(page).to have_css("summary", text: "Version History (1)")
      expect(page).to have_css("a[href='/v/2']", visible: :all)
      expect(page).to have_css("td", text: "Gandalf", visible: :all)
      expect(page).to have_css("time[data-local-time='2026-01-02T15:04:00Z']", visible: :all)
    end

    it "renders an empty table for no versions" do
      render_inline(described_class.new(rows: []))
      expect(page).to have_css("summary", text: "Version History (0)")
      expect(page).to have_no_css("tbody tr")
    end
  end
end
