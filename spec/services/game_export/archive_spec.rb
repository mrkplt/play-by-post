require "rails_helper"
require "zip"

# Archive owns the zip layout: which entries exist, where they sit, and what
# each one holds. Reads is stubbed throughout — the rows are someone else's
# job, and built records keep this to paths and content wiring.
RSpec.describe GameExport::Archive, :db do
  let(:game) { build_stubbed(:game, name: "Sunken Archive") }
  let(:prefix) { "sunken-archive-export-2026-06-15/" }

  def reads(scenes: [], characters: [], versions: [], pages: [], notebook_entries: [], files: [],
            page_versions: [], notebook_entry_versions: [])
    instance_double(
      GameExport::Reads,
      members_for: [], files_for: files, links_for: [], participants_for: [],
      published_posts_for: [], scenes_for: scenes, characters_for: characters,
      versions_for: versions, pages_for: pages, notebook_entries_for: notebook_entries,
      page_versions_for: page_versions, notebook_entry_versions_for: notebook_entry_versions
    )
  end

  # A GameFile-shaped double whose blob streams `bytes` when downloaded, so the
  # archive's chunked write path is exercised without Active Storage.
  def file_double(filename:, bytes: "PDF-BYTES", attached: true)
    blob = instance_double(ActiveStorage::Blob)
    allow(blob).to receive(:download) { |&block| block.call(bytes) }
    # Attached::One reaches blob/attached? through delegation, so a verifying
    # double can't stand in for it — a bare double models the surface used here.
    attachment = double("file", attached?: attached, blob: blob)
    # The same files_for result feeds the manifest too, so stub the columns
    # ManifestDocuments reads (byte_size/content_type/created_at) alongside the
    # streaming surface (filename/file).
    instance_double(
      GameFile,
      filename: filename, file: attachment,
      byte_size: bytes.bytesize, content_type: "application/pdf",
      created_at: Time.utc(2026, 1, 1)
    )
  end

  def entry_names(data)
    names = []
    Zip::InputStream.open(StringIO.new(data)) do |zip|
      while (entry = zip.get_next_entry)
        names << entry.name
      end
    end
    names
  end

  def content_of(data, name)
    Zip::InputStream.open(StringIO.new(data)) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read.force_encoding(Encoding::UTF_8) if entry.name == name
      end
    end
    nil
  end

  def archive_for(scenes: [], notebook: false, **rows)
    Zip::OutputStream.write_buffer do |zip|
      archive = described_class.new(zip, reads(scenes: scenes, **rows), game: game, prefix: prefix)
      archive.write_game(scenes)
      archive.write_notebook if notebook
    end.string
  end

  describe "#write_game" do
    it "writes the readme, and the files and links manifests" do
      names = entry_names(archive_for)

      expect(names).to include("#{prefix}README.md", "#{prefix}files_manifest.md", "#{prefix}links_manifest.md")
    end

    it "roots every entry at the prefix it was given" do
      expect(entry_names(archive_for)).to all(start_with(prefix))
    end

    it "streams each uploaded file's bytes into files/, slugged and extension-preserved" do
      data = archive_for(files: [ file_double(filename: "My Map.PDF", bytes: "map-bytes") ])

      expect(entry_names(data)).to include("#{prefix}files/my-map.pdf")
      expect(content_of(data, "#{prefix}files/my-map.pdf")).to eq("map-bytes")
    end

    it "disambiguates files that slug to the same name" do
      names = entry_names(archive_for(files: [
        file_double(filename: "notes.txt"), file_double(filename: "Notes.txt")
      ]))

      expect(names).to include("#{prefix}files/notes.txt", "#{prefix}files/notes-2.txt")
    end

    it "skips a GameFile whose blob is not attached" do
      names = entry_names(archive_for(files: [ file_double(filename: "ghost.pdf", attached: false) ]))

      expect(names).not_to include(a_string_matching(%r{files/ghost}))
    end

    it "writes scene info and posts per scene" do
      names = entry_names(archive_for(scenes: [ build_stubbed(:scene, title: "Opening Scene") ]))

      expect(names).to include(
        "#{prefix}scenes/001-opening-scene/scene_info.md",
        "#{prefix}scenes/001-opening-scene/posts.md"
      )
    end

    it "numbers scenes in id order and disambiguates duplicate titles" do
      scenes = [ build_stubbed(:scene, id: 2, title: "Ambush"), build_stubbed(:scene, id: 1, title: "Ambush") ]

      names = entry_names(archive_for(scenes: scenes))

      expect(names).to include(a_string_matching(%r{scenes/001-ambush/}))
      expect(names).to include(a_string_matching(%r{scenes/002-ambush-2/}))
    end

    it "writes a sheet per character" do
      names = entry_names(archive_for(characters: [ build_stubbed(:character, name: "Aria") ]))

      expect(names).to include("#{prefix}characters/aria/current_sheet.md")
    end

    it "writes a file per character version, numbered and dated" do
      version = build_stubbed(:character_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user))

      names = entry_names(
        archive_for(characters: [ build_stubbed(:character, name: "Aria") ], versions: [ version ])
      )

      expect(names).to include("#{prefix}characters/aria/version_history/v001-2026-05-06.md")
    end

    it "writes a markdown file per page, slugged from the title" do
      names = entry_names(archive_for(pages: [ build_stubbed(:page, title: "House Rules") ]))

      expect(names).to include("#{prefix}pages/house-rules.md")
    end

    it "disambiguates pages sharing a title" do
      pages = [ build_stubbed(:page, title: "Lore"), build_stubbed(:page, title: "Lore") ]

      names = entry_names(archive_for(pages: pages))

      expect(names).to include("#{prefix}pages/lore.md", "#{prefix}pages/lore-2.md")
    end

    it "writes a file per page version under the page's version_history, numbered oldest-first" do
      page = build_stubbed(:page, title: "House Rules")
      versions = [
        build_stubbed(:page_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user)),
        build_stubbed(:page_version, created_at: Time.utc(2026, 5, 7), edited_by: build_stubbed(:user))
      ]

      names = entry_names(archive_for(pages: [ page ], page_versions: versions))

      expect(names).to include(
        "#{prefix}pages/house-rules/version_history/v001-2026-05-06.md",
        "#{prefix}pages/house-rules/version_history/v002-2026-05-07.md"
      )
    end

    it "writes no notebook directory on its own" do
      names = entry_names(archive_for(notebook_entries: [ build_stubbed(:notebook_entry, title: "Secret") ]))

      expect(names).not_to include(a_string_matching(%r{notebook/}))
    end
  end

  describe "#write_notebook" do
    it "writes a markdown file per entry, slugged from the title" do
      entries = [ build_stubbed(:notebook_entry, title: "Wandering Merchant") ]

      names = entry_names(archive_for(notebook: true, notebook_entries: entries))

      expect(names).to include("#{prefix}notebook/wandering-merchant.md")
    end

    it "disambiguates entries sharing a title" do
      entries = [ build_stubbed(:notebook_entry, title: "Lead"), build_stubbed(:notebook_entry, title: "Lead") ]

      names = entry_names(archive_for(notebook: true, notebook_entries: entries))

      expect(names).to include("#{prefix}notebook/lead.md", "#{prefix}notebook/lead-2.md")
    end

    it "writes a file per entry version under the entry's version_history" do
      entry = build_stubbed(:notebook_entry, title: "Wandering Merchant")
      version = build_stubbed(:notebook_entry_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user))

      names = entry_names(archive_for(notebook: true, notebook_entries: [ entry ], notebook_entry_versions: [ version ]))

      expect(names).to include("#{prefix}notebook/wandering-merchant/version_history/v001-2026-05-06.md")
    end
  end

  # Each write is wiring a document builder to an entry. The builders are
  # pinned in their own specs; here it is enough that the bytes written match
  # what the builder produces for the same input.
  describe "content wiring" do
    it "writes the readme's own content" do
      data = archive_for

      expect(content_of(data, "#{prefix}README.md")).to eq(GameExport::ReadmeDocument.call(game, [], []))
    end

    it "writes the files manifest's own content" do
      data = archive_for

      expect(content_of(data, "#{prefix}files_manifest.md")).to eq(GameExport::ManifestDocuments.files([]))
    end

    it "writes the links manifest's own content" do
      data = archive_for

      expect(content_of(data, "#{prefix}links_manifest.md")).to eq(GameExport::ManifestDocuments.links([]))
    end

    it "writes each scene's own info and posts content" do
      scene = build_stubbed(:scene, title: "Opening Scene")
      data = archive_for(scenes: [ scene ])

      expect(content_of(data, "#{prefix}scenes/001-opening-scene/scene_info.md"))
        .to eq(GameExport::SceneDocuments.info(scene, []))
      expect(content_of(data, "#{prefix}scenes/001-opening-scene/posts.md"))
        .to eq(GameExport::SceneDocuments.posts([]))
    end

    it "writes each character's own sheet and version content" do
      character = build_stubbed(:character, name: "Aria")
      version = build_stubbed(:character_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user))
      data = archive_for(characters: [ character ], versions: [ version ])

      expect(content_of(data, "#{prefix}characters/aria/current_sheet.md"))
        .to eq(GameExport::CharacterDocuments.sheet(character))
      expect(content_of(data, "#{prefix}characters/aria/version_history/v001-2026-05-06.md"))
        .to eq(GameExport::CharacterDocuments.version(version, 1))
    end

    it "writes each page's own content" do
      page = build_stubbed(:page, title: "House Rules")
      data = archive_for(pages: [ page ])

      expect(content_of(data, "#{prefix}pages/house-rules.md")).to eq(GameExport::ProseDocuments.page(page))
    end

    it "writes each notebook entry's own content" do
      entry = build_stubbed(:notebook_entry, title: "Wandering Merchant")
      data = archive_for(notebook: true, notebook_entries: [ entry ])

      expect(content_of(data, "#{prefix}notebook/wandering-merchant.md"))
        .to eq(GameExport::ProseDocuments.notebook_entry(entry))
    end

    it "writes each page version's own content" do
      page = build_stubbed(:page, title: "House Rules")
      version = build_stubbed(:page_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user))
      data = archive_for(pages: [ page ], page_versions: [ version ])

      expect(content_of(data, "#{prefix}pages/house-rules/version_history/v001-2026-05-06.md"))
        .to eq(GameExport::ProseDocuments.version(version, 1))
    end

    it "writes each notebook entry version's own content" do
      entry = build_stubbed(:notebook_entry, title: "Wandering Merchant")
      version = build_stubbed(:notebook_entry_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user))
      data = archive_for(notebook: true, notebook_entries: [ entry ], notebook_entry_versions: [ version ])

      expect(content_of(data, "#{prefix}notebook/wandering-merchant/version_history/v001-2026-05-06.md"))
        .to eq(GameExport::ProseDocuments.version(version, 1))
    end
  end
end
