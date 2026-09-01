require "rails_helper"
require "zip"

# ZipWriter owns the low-level mechanics: prefixing, blob streaming, slug
# de-dup, and the numbered version-history layout. Each method is exercised
# against a real Zip::OutputStream and read back.
RSpec.describe GameExport::ZipWriter do
  let(:prefix) { "game-export-2026-06-15/" }

  def written(&block)
    Zip::OutputStream.write_buffer do |zip|
      block.call(described_class.new(zip, prefix))
    end.string
  end

  def entries(data)
    [].tap do |names|
      Zip::InputStream.open(StringIO.new(data)) do |zip|
        while (entry = zip.get_next_entry)
          names << entry.name
        end
      end
    end
  end

  def content_of(data, name)
    Zip::InputStream.open(StringIO.new(data)) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read.force_encoding(Encoding::UTF_8) if entry.name == name
      end
    end
    nil
  end

  describe "#entry" do
    it "prefixes the path and writes the content" do
      data = written { |w| w.entry("README.md", "hello") }

      expect(content_of(data, "#{prefix}README.md")).to eq("hello")
    end
  end

  describe "#blob_entry" do
    it "streams the blob's chunks into a prefixed entry" do
      blob = instance_double(ActiveStorage::Blob)
      allow(blob).to receive(:download) do |&block|
        block.call("chunk-1-")
        block.call("chunk-2")
      end

      data = written { |w| w.blob_entry("files/doc.pdf", blob) }

      expect(content_of(data, "#{prefix}files/doc.pdf")).to eq("chunk-1-chunk-2")
    end
  end

  describe "#each_slugged" do
    it "yields each record with a slug of the named attribute" do
      records = [ double(title: "House Rules") ]
      slugs = []

      written { |w| w.each_slugged(records, :title) { |_record, slug| slugs << slug } }

      expect(slugs).to eq([ "house-rules" ])
    end

    it "disambiguates repeats with its own tracker" do
      records = [ double(title: "Lore"), double(title: "Lore") ]
      slugs = []

      written { |w| w.each_slugged(records, :title) { |_record, slug| slugs << slug } }

      expect(slugs).to eq([ "lore", "lore-2" ])
    end
  end

  describe "#version_history" do
    it "writes a numbered, dated entry per version, oldest-first" do
      versions = [
        double(created_at: Time.utc(2026, 5, 6)),
        double(created_at: Time.utc(2026, 5, 7))
      ]

      data = written do |w|
        w.version_history("pages/house-rules", versions) { |_v, number| "body #{number}" }
      end

      expect(entries(data)).to include(
        "#{prefix}pages/house-rules/version_history/v001-2026-05-06.md",
        "#{prefix}pages/house-rules/version_history/v002-2026-05-07.md"
      )
      expect(content_of(data, "#{prefix}pages/house-rules/version_history/v002-2026-05-07.md"))
        .to eq("body 2")
    end

    it "writes nothing when there are no versions" do
      data = written { |w| w.version_history("pages/x", []) { |_v, n| "b#{n}" } }

      expect(entries(data)).to be_empty
    end
  end
end
