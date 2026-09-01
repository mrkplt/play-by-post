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

  describe "#version" do
    let(:editor) { build_stubbed(:user).tap { |u| allow(u).to receive(:display_name).and_return("Jo") } }

    def content(version, number = 1)
      GameExport::ProseDocuments.version(version, number)
    end

    it "heads the version with its number and date, date only (no time component)" do
      version = build_stubbed(:page_version, created_at: Time.utc(2026, 5, 6, 14, 30), edited_by: editor)
      expect(content(version, 3)).to include("# Version 3 — 2026-05-06\n")
      expect(content(version, 3)).not_to match(/Version 3 — 2026-05-06 \d/)
    end

    it "credits the editor by display name" do
      version = build_stubbed(:page_version, edited_by: editor)
      expect(content(version)).to include("**Edited by:** Jo")
    end

    it "records the title as it stood at that version" do
      version = build_stubbed(:page_version, title: "Old House Rules", edited_by: editor)
      expect(content(version)).to include("**Title:** Old House Rules")
    end

    it "includes the versioned body" do
      version = build_stubbed(:page_version, body: "Roll **once**.", edited_by: editor)
      expect(content(version)).to include("Roll **once**.")
    end

    it "renders a notebook entry version the same way" do
      version = build_stubbed(:notebook_entry_version, title: "Old Plan", body: "Scheme.", edited_by: editor)
      expect(content(version, 2)).to include("# Version 2", "**Edited by:** Jo", "**Title:** Old Plan", "Scheme.")
    end
  end

  describe "#scene_summary" do
    let(:editor) { build_stubbed(:user).tap { |u| allow(u).to receive(:display_name).and_return("Jo") } }

    def content(summary)
      GameExport::ProseDocuments.scene_summary(summary)
    end

    it "titles it and includes the body" do
      summary = build_stubbed(:scene_summary, body: "They **escaped**.")
      expect(content(summary)).to include("# Scene Summary", "They **escaped**.")
    end

    it "marks a hand-written summary's origin" do
      summary = build_stubbed(:scene_summary, generated_at: nil)
      expect(content(summary)).to include("**Origin:** Hand-written")
      expect(content(summary)).not_to include("AI-generated")
    end

    it "marks an AI-generated summary's origin" do
      summary = build_stubbed(:scene_summary, generated_at: Time.current)
      expect(content(summary)).to include("**Origin:** AI-generated")
    end

    it "credits the editor when the summary was edited" do
      summary = build_stubbed(:scene_summary, edited_at: Time.current, edited_by: editor)
      expect(content(summary)).to include("**Edited by:** Jo")
    end

    it "separates the provenance lines with a blank line" do
      summary = build_stubbed(:scene_summary, generated_at: Time.current, edited_at: Time.current, edited_by: editor)
      expect(content(summary)).to include("**Origin:** AI-generated\n\n**Edited by:** Jo")
    end

    it "omits the editor line when the summary was never edited" do
      summary = build_stubbed(:scene_summary, edited_at: nil)
      expect(content(summary)).not_to include("**Edited by:**")
    end

    it "flags a draft summary" do
      summary = build_stubbed(:scene_summary, draft: true)
      expect(content(summary)).to include("**Status:** Draft")
    end

    it "does not flag a published summary as a draft" do
      summary = build_stubbed(:scene_summary, draft: false)
      expect(content(summary)).not_to include("Draft")
    end

    it "notes an empty draft body rather than writing nothing" do
      summary = build_stubbed(:scene_summary, draft: true, body: nil)
      expect(content(summary)).to include("_No content._")
    end
  end
end
