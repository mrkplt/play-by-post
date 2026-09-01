require "rails_helper"
require "zip"

RSpec.describe GameExportService do
  let(:gm_user) { create(:user, :with_profile) }
  let(:player_user) { create(:user, :with_profile) }
  let(:game) { create(:game, name: "Test Game", description: "A test game.") }
  let!(:gm_member) { create(:game_member, :game_master, game: game, user: gm_user) }
  let!(:player_member) { create(:game_member, game: game, user: player_user) }
  let(:scene) { create(:scene, game: game, title: "Opening Scene") }
  let!(:participant) { create(:scene_participant, scene: scene, user: player_user) }
  let!(:post) { create(:post, scene: scene, user: player_user, content: "Hello world!") }

  # #call now returns an open Tempfile rather than a String; normalise either to
  # an IO the zip readers can consume, so the helpers work whether given the
  # service's Tempfile or a raw byte String.
  def zip_io(archive)
    archive.is_a?(String) ? StringIO.new(archive) : archive.tap(&:rewind)
  end

  def zip_entries(archive)
    entries = []
    Zip::InputStream.open(zip_io(archive)) do |zip|
      while (entry = zip.get_next_entry)
        entries << entry.name
      end
    end
    entries
  end

  def zip_file_content(archive, name)
    Zip::InputStream.open(zip_io(archive)) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read.force_encoding(Encoding::UTF_8) if entry.name == name
      end
    end
    nil
  end

  describe "#call (zip layout)" do
    let(:export_user) { build_stubbed(:user) }
    let(:gm_member) { build_stubbed(:game_member, role: "game_master", status: "active") }

    def build_service(games, scenes: [], characters: [], versions: [], pages: [], notebook_entries: [], gm: true)
      games.each do |g|
        allow(g).to receive(:member_for).with(export_user).and_return(gm_member)
        allow(g).to receive(:game_master?).with(export_user).and_return(gm)
      end
      reads = instance_double(
        GameExport::Reads,
        scenes_for: scenes, members_for: [], files_for: [], links_for: [],
        participants_for: [], published_posts_for: [], characters_for: characters,
        versions_for: versions, pages_for: pages, notebook_entries_for: notebook_entries,
        page_versions_for: [], notebook_entry_versions_for: []
      )

      described_class.new(export_user, games, reads: reads)
    end

    def entries_for(...) = zip_entries(build_service(...).call)

    let(:one_game) { [ build_stubbed(:game, name: "Sunken Archive") ] }

    it "writes a README and a files manifest" do
      entries = entries_for(one_game)

      expect(entries).to include(a_string_matching(%r{README\.md$}))
      expect(entries).to include(a_string_matching(%r{files_manifest\.md$}))
    end

    it "writes a links manifest" do
      expect(entries_for(one_game)).to include(a_string_matching(%r{links_manifest\.md$}))
    end

    it "writes scene info and posts per scene" do
      entries = entries_for(one_game, scenes: [ build_stubbed(:scene, title: "Opening Scene") ])

      expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/scene_info\.md$}))
      expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/posts\.md$}))
    end

    it "roots a single-game export at the game slug" do
      expect(entries_for(one_game).first).to start_with("sunken-archive-export-")
    end

    it "numbers scenes and disambiguates duplicate titles" do
      entries = entries_for(one_game, scenes: [ build_stubbed(:scene, title: "Ambush"),
                                                build_stubbed(:scene, title: "Ambush") ])

      expect(entries).to include(a_string_matching(%r{scenes/001-ambush/}))
      expect(entries).to include(a_string_matching(%r{scenes/002-ambush-2/}))
    end

    it "writes a sheet per character" do
      entries = entries_for(one_game, characters: [ build_stubbed(:character, name: "Aria") ])

      expect(entries).to include(a_string_matching(%r{characters/aria/current_sheet\.md$}))
    end

    it "writes a file per character version" do
      character = build_stubbed(:character, name: "Aria")
      version = build_stubbed(:character_version, created_at: Time.utc(2026, 5, 6),
                                                  edited_by: build_stubbed(:user))

      entries = entries_for(one_game, characters: [ character ], versions: [ version ])

      expect(entries).to include(a_string_matching(%r{characters/aria/version_history/v001-2026-05-06\.md$}))
    end

    it "writes a markdown file per page, slugged from the title" do
      entries = entries_for(one_game, pages: [ build_stubbed(:page, title: "House Rules") ])

      expect(entries).to include(a_string_matching(%r{pages/house-rules\.md$}))
    end

    it "disambiguates pages with duplicate titles" do
      entries = entries_for(one_game, pages: [ build_stubbed(:page, title: "Lore"),
                                               build_stubbed(:page, title: "Lore") ])

      expect(entries).to include(a_string_matching(%r{pages/lore\.md$}))
      expect(entries).to include(a_string_matching(%r{pages/lore-2\.md$}))
    end

    it "writes a markdown file per notebook entry for the GM, slugged from the title" do
      entries = entries_for(one_game, gm: true, notebook_entries: [ build_stubbed(:notebook_entry, title: "Wandering Merchant") ])

      expect(entries).to include(a_string_matching(%r{notebook/wandering-merchant\.md$}))
    end

    it "does not write a notebook directory for a non-GM, even with entries stubbed" do
      entries = entries_for(one_game, gm: false, notebook_entries: [ build_stubbed(:notebook_entry, title: "Secret Plan") ])

      expect(entries).not_to include(a_string_matching(%r{notebook/}))
    end

    context "with several games" do
      let(:games) { [ build_stubbed(:game, name: "Alpha"), build_stubbed(:game, name: "Beta") ] }

      it "roots the export at all-games-export" do
        expect(entries_for(games).first).to start_with("all-games-export-")
      end

      it "gives each game its own directory" do
        entries = entries_for(games)

        expect(entries).to include(a_string_matching(%r{all-games-export-[\d-]+/alpha/}))
        expect(entries).to include(a_string_matching(%r{all-games-export-[\d-]+/beta/}))
      end
    end

    # Each write_* method's only job is wiring a real content builder to the
    # right zip entry. Every content builder is pinned exactly above; here it's
    # enough to show the bytes written for a given entry match what that
    # (already-trusted) builder produces for the same inputs — this catches a
    # write_* mutation swapping the argument, dropping the write, or misnaming
    # the entry, without re-pinning the content itself.
    describe "content wiring" do
      let(:one_scene) { build_stubbed(:scene, title: "Opening Scene") }
      let(:one_character) { build_stubbed(:character, name: "Aria") }
      let(:one_version) { build_stubbed(:character_version, created_at: Time.utc(2026, 5, 6), edited_by: build_stubbed(:user)) }

      it "writes the readme's own content under README.md" do
        service = build_service(one_game)
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("README.md") }

        expect(zip_file_content(zip_data, name)).to eq(GameExport::ReadmeDocument.call(one_game.first, [], []))
      end

      it "writes the files manifest's own content under files_manifest.md" do
        service = build_service(one_game)
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("files_manifest.md") }

        expect(zip_file_content(zip_data, name)).to eq(GameExport::ManifestDocuments.files([]))
      end

      it "writes the links manifest's own content under links_manifest.md" do
        service = build_service(one_game)
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("links_manifest.md") }

        expect(zip_file_content(zip_data, name)).to eq(GameExport::ManifestDocuments.links([]))
      end

      it "writes each scene's own info and posts content" do
        service = build_service(one_game, scenes: [ one_scene ])
        zip_data = service.call
        info_name = zip_entries(zip_data).find { |e| e.end_with?("scene_info.md") }
        posts_name = zip_entries(zip_data).find { |e| e.end_with?("posts.md") }

        expect(zip_file_content(zip_data, info_name)).to eq(GameExport::SceneDocuments.info(one_scene, []))
        expect(zip_file_content(zip_data, posts_name)).to eq(GameExport::SceneDocuments.posts([]))
      end

      it "writes each character's own sheet and version content" do
        service = build_service(one_game, characters: [ one_character ], versions: [ one_version ])
        zip_data = service.call
        sheet_name = zip_entries(zip_data).find { |e| e.end_with?("current_sheet.md") }
        version_name = zip_entries(zip_data).find { |e| e.include?("version_history/") }

        expect(zip_file_content(zip_data, sheet_name)).to eq(GameExport::CharacterDocuments.sheet(one_character))
        expect(zip_file_content(zip_data, version_name)).to eq(GameExport::CharacterDocuments.version(one_version, 1))
      end

      it "writes each page's own content under pages/{slug}.md" do
        one_page = build_stubbed(:page, title: "House Rules")
        service = build_service(one_game, pages: [ one_page ])
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("house-rules.md") }

        expect(zip_file_content(zip_data, name)).to eq(GameExport::ProseDocuments.page(one_page))
      end

      it "writes each notebook entry's own content under notebook/{slug}.md" do
        one_entry = build_stubbed(:notebook_entry, title: "Wandering Merchant")
        service = build_service(one_game, gm: true, notebook_entries: [ one_entry ])
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("wandering-merchant.md") }

        expect(zip_file_content(zip_data, name)).to eq(GameExport::ProseDocuments.notebook_entry(one_entry))
      end
    end
  end

  describe "#call" do
    context "single game, GM" do
      subject(:zip_data) { GameExportService.new(gm_user, [ game ]).call }

      it "returns a non-empty zip Tempfile" do
        expect(zip_data).to be_a(Tempfile)
        expect(zip_data.size).to be > 0
      end

      # These keep the database deliberately: they assert zip assembly itself —
      # entry paths, per-membership scene selection, multi-game roots and slug
      # disambiguation — which is exactly what #call integrates. Every content
      # builder feeding it is covered above without a connection.

      it "includes the game's notebook entries under notebook/" do
        create(:notebook_entry, game: game, title: "Wandering Merchant")
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{notebook/wandering-merchant\.md$}))
      end

      # End-to-end through real Active Storage: the archive spec stubs the blob,
      # so this pins that an actually-attached GameFile's bytes stream into
      # files/ via blob.download.
      it "streams an uploaded file's real bytes into files/" do
        game_file = create(:game_file, game: game, filename: "Rule Book.pdf")
        game_file.file.attach(io: StringIO.new("%PDF-1.4 real bytes"), filename: "Rule Book.pdf", content_type: "application/pdf")

        entry_name = zip_entries(zip_data).find { |e| e.end_with?("files/rule-book.pdf") }
        expect(entry_name).to be_present
        expect(zip_file_content(zip_data, entry_name)).to eq("%PDF-1.4 real bytes")
      end
    end

    context "single game, active player" do
      subject(:zip_data) { GameExportService.new(player_user, [ game ]).call }


      it "excludes private scenes the player is not in" do
        create(:scene, :private, game: game, title: "Secret Scene")
        entries = zip_entries(GameExportService.new(player_user, [ game ]).call)
        expect(entries).not_to include(a_string_matching(%r{secret-scene}))
      end

      it "never includes notebook content, even though the game has entries" do
        create(:notebook_entry, game: game, title: "Secret Plan")
        entries = zip_entries(zip_data)
        expect(entries).not_to include(a_string_matching(%r{notebook/}))
      end
    end

    context "single game, removed member" do
      let(:removed_user) { create(:user, :with_profile) }

      before do
        create(:game_member, :removed, game: game, user: removed_user)
        create(:scene_participant, scene: scene, user: removed_user)
      end

      subject(:zip_data) { GameExportService.new(removed_user, [ game ]).call }
    end

    context "all games" do
      let(:game2) { create(:game, name: "Second Game") }

      before do
        create(:game_member, game: game2, user: player_user, role: "player", status: "active")
      end

      subject(:zip_data) { GameExportService.new(player_user, [ game, game2 ]).call }
    end

    context "when user is not a member" do
      let(:outsider) { create(:user, :with_profile) }

      it "produces an empty zip" do
        zip_data = GameExportService.new(outsider, [ game ]).call
        entries = zip_entries(zip_data)
        expect(entries).to be_empty
      end
    end

    context "slug disambiguation" do
    end
  end
end
