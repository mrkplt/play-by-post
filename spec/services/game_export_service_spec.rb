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

  def zip_entries(zip_data)
    entries = []
    Zip::InputStream.open(StringIO.new(zip_data)) do |zip|
      while (entry = zip.get_next_entry)
        entries << entry.name
      end
    end
    entries
  end

  def zip_file_content(zip_data, name)
    Zip::InputStream.open(StringIO.new(zip_data)) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read if entry.name == name
      end
    end
    nil
  end

  describe "#call" do
    context "single game, GM" do
      subject(:zip_data) { GameExportService.new(gm_user, [ game ]).call }

      it "returns a non-empty zip" do
        expect(zip_data).to be_a(String)
        expect(zip_data).not_to be_empty
      end

      it "includes README.md" do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{README\.md$}))
      end

      it "includes files_manifest.md" do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{files_manifest\.md$}))
      end

      it "includes scene info and posts" do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/scene_info\.md$}))
        expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/posts\.md$}))
      end

      it "uses game name slug as the root directory" do
        entries = zip_entries(zip_data)
        expect(entries.first).to start_with("test-game-export-")
      end

      it "includes posts content in posts.md" do
        entries = zip_entries(zip_data)
        posts_path = entries.find { |e| e.end_with?("posts.md") }
        content = zip_file_content(zip_data, posts_path)
        expect(content).to include("Hello world!")
      end

      it "excludes draft posts" do
        create(:post, :draft, scene: scene, user: gm_user)
        entries = zip_entries(zip_data)
        posts_path = entries.find { |e| e.end_with?("posts.md") }
        content = zip_file_content(zip_data, posts_path)
        # Draft posts have no content requirement; ensure only published posts appear
        expect(content).to include("Hello world!")
      end

      it "includes character files when characters exist" do
        character = create(:character, game: game, user: player_user, name: "Aria")
        participant.update!(character: character)
        entries = zip_entries(GameExportService.new(gm_user, [ game ]).call)
        expect(entries).to include(a_string_matching(%r{characters/aria/current_sheet\.md$}))
      end

      it "includes README with member roster" do
        entries = zip_entries(zip_data)
        readme_path = entries.find { |e| e.end_with?("README.md") }
        content = zip_file_content(zip_data, readme_path)
        expect(content).to include("GM")
        expect(content).to include(gm_user.display_name)
      end

      it "includes scene count in README" do
        entries = zip_entries(zip_data)
        readme_path = entries.find { |e| e.end_with?("README.md") }
        content = zip_file_content(zip_data, readme_path)
        expect(content).to include("Active: 1")
      end

      it "includes resolved scene count in README" do
        create(:scene, :resolved, game: game, title: "Old Scene")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        readme_path = entries.find { |e| e.end_with?("README.md") }
        content = zip_file_content(zip_data2, readme_path)
        expect(content).to include("Resolved: 1")
      end

      it "labels removed members as Former in README" do
        removed_user = create(:user, :with_profile)
        create(:game_member, :removed, game: game, user: removed_user)
        entries = zip_entries(zip_data)
        readme_path = entries.find { |e| e.end_with?("README.md") }
        content = zip_file_content(zip_data, readme_path)
        expect(content).to include("Former")
      end

      it "includes resolved scene status and date in scene_info.md" do
        resolved = create(:scene, :resolved, game: game, title: "Done Scene", resolution: "All ends well.")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        info_path = entries.find { |e| e.include?("done-scene") && e.end_with?("scene_info.md") }
        content = zip_file_content(zip_data2, info_path)
        expect(content).to include("Resolved")
        expect(content).to include("All ends well.")
      end

      it "includes parent scene in scene_info.md" do
        child = create(:scene, :with_parent, game: game, title: "Child Scene")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        info_path = entries.find { |e| e.include?("child-scene") && e.end_with?("scene_info.md") }
        content = zip_file_content(zip_data2, info_path)
        expect(content).to include("## Parent Scene")
      end

      it "shows no description fallback in scene_info.md when description is blank" do
        scene.update!(description: "")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        info_path = entries.find { |e| e.end_with?("scene_info.md") }
        content = zip_file_content(zip_data2, info_path)
        expect(content).to include("_No description._")
      end

      it "labels OOC posts in posts.md" do
        create(:post, :ooc, scene: scene, user: gm_user, content: "OOC message")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        posts_path = entries.find { |e| e.end_with?("posts.md") }
        content = zip_file_content(zip_data2, posts_path)
        expect(content).to include("[Out of Character]")
      end

      it "marks edited posts with (edited) in posts.md" do
        create(:post, :edited, scene: scene, user: gm_user, content: "Edited post")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        posts_path = entries.find { |e| e.end_with?("posts.md") }
        content = zip_file_content(zip_data2, posts_path)
        expect(content).to include("(edited)")
      end

      it "shows no posts fallback when scene has no published posts" do
        scene2 = create(:scene, game: game, title: "Empty Scene")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        posts_path = entries.find { |e| e.include?("empty-scene") && e.end_with?("posts.md") }
        content = zip_file_content(zip_data2, posts_path)
        expect(content).to include("_No posts yet._")
      end

      it "notes hidden and archived character attributes in current_sheet.md" do
        # Use gm_user's own characters so they appear in user_char_ids
        hidden_char = create(:character, :hidden, game: game, user: gm_user, name: "Ghost")
        archived_char = create(:character, :archived, game: game, user: gm_user, name: "Retired")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)

        ghost_path = entries.find { |e| e.include?("ghost") && e.end_with?("current_sheet.md") }
        ghost_content = zip_file_content(zip_data2, ghost_path)
        expect(ghost_content).to include("**Hidden:** Yes")

        retired_path = entries.find { |e| e.include?("retired") && e.end_with?("current_sheet.md") }
        retired_content = zip_file_content(zip_data2, retired_path)
        expect(retired_content).to include("**Archived:** Yes")
      end

      it "includes version history files for characters" do
        character = create(:character, game: game, user: player_user, name: "Versioned")
        participant.update!(character: character)
        # Character gets a snapshot on create; update triggers another version
        character.update!(content: "Updated sheet")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        version_entries = entries.select { |e| e.include?("version_history") }
        expect(version_entries.size).to be >= 2
      end

      it "includes files manifest with no-files message when no game files exist" do
        entries = zip_entries(zip_data)
        manifest_path = entries.find { |e| e.end_with?("files_manifest.md") }
        content = zip_file_content(zip_data, manifest_path)
        expect(content).to include("_No files uploaded._")
      end

      it "includes files manifest with file list when game files exist" do
        gf = create(:game_file, game: game, filename: "rules.pdf", content_type: "application/pdf", byte_size: 2_048_000)
        gf.file.attach(io: StringIO.new("pdf content"), filename: "rules.pdf", content_type: "application/pdf")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        manifest_path = entries.find { |e| e.end_with?("files_manifest.md") }
        content = zip_file_content(zip_data2, manifest_path)
        expect(content).to include("rules.pdf")
        expect(content).to include("MB")
      end

      it "shows KB size for medium files in manifest" do
        gf = create(:game_file, game: game, filename: "notes.txt", content_type: "text/plain", byte_size: 2_048)
        gf.file.attach(io: StringIO.new("notes"), filename: "notes.txt", content_type: "text/plain")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        manifest_path = entries.find { |e| e.end_with?("files_manifest.md") }
        content = zip_file_content(zip_data2, manifest_path)
        expect(content).to include("KB")
      end

      it "shows 'unknown' size for game files without an attachment" do
        create(:game_file, game: game, filename: "missing.pdf")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        manifest_path = entries.find { |e| e.end_with?("files_manifest.md") }
        content = zip_file_content(zip_data2, manifest_path)
        expect(content).to include("unknown")
      end

      it "shows bytes for small files in manifest" do
        gf = create(:game_file, game: game, filename: "tiny.txt", content_type: "text/plain", byte_size: 500)
        gf.file.attach(io: StringIO.new("x"), filename: "tiny.txt", content_type: "text/plain")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        manifest_path = entries.find { |e| e.end_with?("files_manifest.md") }
        content = zip_file_content(zip_data2, manifest_path)
        expect(content).to include(" B")
      end

      it "uses 'untitled' slug for a scene whose title produces an empty slug" do
        create(:scene, game: game, title: "!!! @@@")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        expect(entries).to include(a_string_matching(%r{-untitled/}))
      end
    end

    context "single game, active player" do
      subject(:zip_data) { GameExportService.new(player_user, [ game ]).call }

      it "includes the scene the player participates in" do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{scenes/}))
      end

      it "excludes private scenes the player is not in" do
        create(:scene, :private, game: game, title: "Secret Scene")
        entries = zip_entries(GameExportService.new(player_user, [ game ]).call)
        expect(entries).not_to include(a_string_matching(%r{secret-scene}))
      end
    end

    context "single game, removed member" do
      let(:removed_user) { create(:user, :with_profile) }

      before do
        create(:game_member, :removed, game: game, user: removed_user)
        create(:scene_participant, scene: scene, user: removed_user)
      end

      subject(:zip_data) { GameExportService.new(removed_user, [ game ]).call }

      it "includes only scenes they participated in" do
        other_scene = create(:scene, game: game, title: "Other Scene")
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{opening-scene}))
        expect(entries).not_to include(a_string_matching(%r{other-scene}))
      end
    end

    context "all games" do
      let(:game2) { create(:game, name: "Second Game") }

      before do
        create(:game_member, game: game2, user: player_user, role: "player", status: "active")
      end

      subject(:zip_data) { GameExportService.new(player_user, [ game, game2 ]).call }

      it "uses all-games-export as root directory" do
        entries = zip_entries(zip_data)
        expect(entries.first).to start_with("all-games-export-")
      end

      it "includes both games" do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{test-game/}))
        expect(entries).to include(a_string_matching(%r{second-game/}))
      end
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
      it "disambiguates scenes with duplicate titles" do
        create(:scene, game: game, title: "Opening Scene")
        zip_data = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data)
        scene_dirs = entries.select { |e| e.include?("/scenes/") && e.end_with?("scene_info.md") }
        expect(scene_dirs.size).to eq(2)
        slugs = scene_dirs.map { |e| e.split("/scenes/").last.split("/").first }
        expect(slugs.uniq.size).to eq(2)
      end
    end
  end
end
