require "rails_helper"

RSpec.describe GameExport::ManifestDocuments, :db do
  describe "#files_manifest_content" do
    let(:exported_game) { build_stubbed(:game) }
    let(:service) { described_class.new(build_stubbed(:user), [ exported_game ]) }

    def file_double(filename: "rules.pdf", content_type: "application/pdf", byte_size: 500, attached: true)
      double(
        file: double(attached?: attached),
        byte_size: byte_size,
        created_at: Time.utc(2026, 1, 1),
        filename: filename,
        content_type: content_type
      )
    end

    def manifest(files)
      GameExport::ManifestDocuments.files(files)
    end

    it "reports when no files have been uploaded" do
      expect(manifest([])).to include("_No files uploaded._")
    end

    it "lists a file with its name and type" do
      content = manifest([ file_double ])

      expect(content).to include("rules.pdf")
      expect(content).to include("application/pdf")
    end

    it "shows MB for large files" do
      expect(manifest([ file_double(byte_size: 2_048_000) ])).to include("MB")
    end

    it "shows KB for medium files" do
      expect(manifest([ file_double(byte_size: 2_048) ])).to include("KB")
    end

    it "shows bytes for small files" do
      expect(manifest([ file_double(byte_size: 500) ])).to include(" B")
    end

    it "shows unknown when the attachment is missing" do
      expect(manifest([ file_double(attached: false) ])).to include("unknown")
    end

    it "renders the full document byte for byte with files" do
      expected = [
        "# Game Files",
        "",
        "| Filename | Type | Size | Uploaded |",
        "|---|---|---|---|",
        "| rules.pdf | application/pdf | 500 B | 2026-01-01 |",
        "",
        "_The files themselves are in the `files/` folder of this export._",
        ""
      ].join("\n")

      expect(manifest([ file_double ])).to eq(expected)
    end

    it "renders the full document byte for byte with no files" do
      expected = [
        "# Game Files",
        "",
        "_No files uploaded._",
        ""
      ].join("\n")

      expect(manifest([])).to eq(expected)
    end
  end

  describe "#links_manifest_content" do
    let(:exported_game) { build_stubbed(:game) }
    let(:service) { described_class.new(build_stubbed(:user), [ exported_game ]) }

    def link_double(description: "Maps", url: "https://maps.example.com")
      double(description: description, url: url)
    end

    def manifest(links)
      GameExport::ManifestDocuments.links(links)
    end

    it "reports when no links have been added" do
      expect(manifest([])).to include("_No links added._")
    end

    it "lists a link's description and URL" do
      content = manifest([ link_double ])

      expect(content).to include("Maps")
      expect(content).to include("https://maps.example.com")
    end

    it "renders the full document byte for byte with links" do
      expected = [
        "# Game Links",
        "",
        "| Description | URL |",
        "|---|---|",
        "| Maps | https://maps.example.com |",
        "",
        "_External links open in a new tab._",
        ""
      ].join("\n")

      expect(manifest([ link_double ])).to eq(expected)
    end

    it "renders the full document byte for byte with no links" do
      expected = [
        "# Game Links",
        "",
        "_No links added._",
        ""
      ].join("\n")

      expect(manifest([])).to eq(expected)
    end
  end
end
