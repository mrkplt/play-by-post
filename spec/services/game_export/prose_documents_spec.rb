require "rails_helper"

RSpec.describe GameExport::ProseDocuments, :db do
  describe "#page_content" do
    def content(page)
      GameExport::ProseDocuments.page(page)
    end

    it "titles the page as an h1" do
      expect(content(build_stubbed(:page, title: "House Rules"))).to include("# House Rules")
    end

    it "includes the markdown body" do
      expect(content(build_stubbed(:page, body: "Roll **twice**."))).to include("Roll **twice**.")
    end

    it "notes an empty body rather than writing nothing" do
      expect(content(build_stubbed(:page, body: nil))).to include("_No content._")
    end
  end

  describe "#notebook_entry_content" do
    def content(entry)
      GameExport::ProseDocuments.notebook_entry(entry)
    end

    it "titles the entry as an h1" do
      expect(content(build_stubbed(:notebook_entry, title: "Wandering Merchant"))).to include("# Wandering Merchant")
    end

    it "includes the status" do
      expect(content(build_stubbed(:notebook_entry, status: "expand"))).to include("**Status:** expand")
    end

    it "includes the markdown body" do
      expect(content(build_stubbed(:notebook_entry, body: "Shows up **twice**."))).to include("Shows up **twice**.")
    end

    it "notes an empty body rather than writing nothing" do
      expect(content(build_stubbed(:notebook_entry, body: nil))).to include("_No content._")
    end
  end
end
