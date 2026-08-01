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

  # README rendering is string building over a member list and a scene list.
  # Stubbing the one read (#members_for) lets it be exercised with built records
  # instead of a persisted game, its members, and a zip round-trip.
  describe "#readme_content" do
    let(:exported_game) { build_stubbed(:game, name: "Test Game", description: "A test game.") }
    let(:service) { described_class.new(build_stubbed(:user), [ exported_game ]) }

    def member(display_name:, role: "player", status: "active")
      user = build_stubbed(:user)
      allow(user).to receive(:display_name).and_return(display_name)
      build_stubbed(:game_member, user: user, role: role, status: status, game: exported_game)
    end

    def readme(members: [], scenes: [])
      allow(service).to receive(:members_for).with(exported_game).and_return(members)
      service.send(:readme_content, exported_game, scenes)
    end

    it "lists a game master as GM" do
      content = readme(members: [ member(display_name: "Dana", role: "game_master") ])

      expect(content).to include("| Dana | GM | Active |")
    end

    it "labels a removed member as Former" do
      content = readme(members: [ member(display_name: "Gus", status: "removed") ])

      expect(content).to include("Former")
    end

    it "counts unresolved scenes as active" do
      content = readme(scenes: [ build_stubbed(:scene), build_stubbed(:scene) ])

      expect(content).to include("- Active: 2")
      expect(content).to include("- Resolved: 0")
    end

    it "counts resolved scenes separately" do
      content = readme(scenes: [ build_stubbed(:scene), build_stubbed(:scene, :resolved) ])

      expect(content).to include("- Active: 1")
      expect(content).to include("- Resolved: 1")
    end

    it "falls back when the description is blank" do
      allow(exported_game).to receive(:description).and_return("")

      expect(readme).to include("_No description._")
    end
  end

  # posts.md and files_manifest.md are string building over a list. Stub the one
  # read each needs and they exercise every branch without a persisted graph or
  # a zip round-trip.
  describe "#posts_content" do
    let(:exported_scene) { build_stubbed(:scene) }
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def post_double(content: "Hello world!", author: "Alice", ooc: false, edited: nil)
      double(
        user: double(display_name: author, email: "alice@example.com"),
        created_at: Time.utc(2026, 1, 1, 12, 0),
        last_edited_at: edited,
        is_ooc?: ooc,
        content: content
      )
    end

    def posts_md(posts)
      allow(service).to receive(:published_posts_for).with(exported_scene).and_return(posts)
      service.send(:posts_content, exported_scene)
    end

    it "renders the post body and author" do
      content = posts_md([ post_double ])

      expect(content).to include("Hello world!")
      expect(content).to include("## Alice — 2026-01-01 12:00 UTC")
    end

    it "falls back to the email when the author has no display name" do
      expect(posts_md([ post_double(author: "") ])).to include("alice@example.com")
    end

    it "shows a fallback when there are no published posts" do
      expect(posts_md([])).to eq("_No posts yet._\n")
    end

    it "labels OOC posts" do
      expect(posts_md([ post_double(ooc: true) ])).to include("[Out of Character]")
    end

    it "marks edited posts" do
      expect(posts_md([ post_double(edited: Time.utc(2026, 1, 2)) ])).to include("(edited)")
    end

    it "does not mark unedited posts" do
      expect(posts_md([ post_double ])).not_to include("(edited)")
    end
  end

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
      allow(service).to receive(:files_for).with(exported_game).and_return(files)
      service.send(:files_manifest_content, exported_game)
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
  end

  describe "#scene_info_content" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def info(scene, participants: [])
      allow(service).to receive(:participants_for).with(scene).and_return(participants)
      service.send(:scene_info_content, scene)
    end

    it "marks an unresolved scene active" do
      expect(info(build_stubbed(:scene))).to include("**Status:** Active")
    end

    it "marks a resolved scene resolved and dates it" do
      resolved_at = Time.utc(2026, 3, 4)
      scene = build_stubbed(:scene, :resolved, resolved_at: resolved_at)

      content = info(scene)

      expect(content).to include("**Status:** Resolved")
      expect(content).to include("**Resolved:** 2026-03-04")
    end

    it "names the parent scene when there is one" do
      parent = build_stubbed(:scene, title: "The Tavern")
      scene = build_stubbed(:scene, parent_scene: parent)

      content = info(scene)

      expect(content).to include("## Parent Scene")
      expect(content).to include("The Tavern")
    end

    it "omits the parent section when there is no parent" do
      expect(info(build_stubbed(:scene, parent_scene: nil))).not_to include("## Parent Scene")
    end

    it "falls back when the description is blank" do
      expect(info(build_stubbed(:scene, description: ""))).to include("_No description._")
    end

    it "lists participants with their character" do
      character = build_stubbed(:character, name: "Aria")
      user = build_stubbed(:user)
      allow(user).to receive(:display_name).and_return("Dana")
      sp = build_stubbed(:scene_participant, user: user, character: character)

      expect(info(build_stubbed(:scene), participants: [ sp ])).to include("| Dana | Aria |")
    end

    it "dashes the character column for a participant without one" do
      user = build_stubbed(:user)
      allow(user).to receive(:display_name).and_return("Gus")
      sp = build_stubbed(:scene_participant, user: user, character: nil)

      expect(info(build_stubbed(:scene), participants: [ sp ])).to include("| Gus | — |")
    end
  end

  describe "#character_sheet_content" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def sheet(character)
      service.send(:character_sheet_content, character)
    end

    it "notes a hidden character" do
      expect(sheet(build_stubbed(:character, :hidden))).to include("**Hidden:** Yes")
    end

    it "notes an archived character" do
      expect(sheet(build_stubbed(:character, :archived))).to include("**Archived:** Yes")
    end

    it "notes an ordinary character as neither" do
      content = sheet(build_stubbed(:character))

      expect(content).to include("**Hidden:** No")
      expect(content).to include("**Archived:** No")
    end
  end

  describe "#slugify" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def slug(text) = service.send(:slugify, text)

    it "lowercases and hyphenates" do
      expect(slug("The Sunken Archive")).to eq("the-sunken-archive")
    end

    it "strips punctuation" do
      expect(slug("Chapter 1: The End!")).to eq("chapter-1-the-end")
    end

    it "collapses repeated separators" do
      expect(slug("a   -  b")).to eq("a-b")
    end

    it "falls back to untitled when nothing survives" do
      expect(slug("!!!")).to eq("untitled")
    end
  end

  describe "#call" do
    context "single game, GM" do
      subject(:zip_data) { GameExportService.new(gm_user, [ game ]).call }

      it "returns a non-empty zip" do
        expect(zip_data).to be_a(String)
        expect(zip_data).not_to be_empty
      end

      # These keep the database deliberately: they assert zip assembly itself —
      # entry paths, per-membership scene selection, multi-game roots and slug
      # disambiguation — which is exactly what #call integrates. Every content
      # builder feeding it is covered above without a connection.
      it "includes README.md", db: true do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{README\.md$}))
      end

      it "includes files_manifest.md", db: true do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{files_manifest\.md$}))
      end

      it "includes scene info and posts", db: true do
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/scene_info\.md$}))
        expect(entries).to include(a_string_matching(%r{scenes/001-opening-scene/posts\.md$}))
      end

      it "uses game name slug as the root directory", db: true do
        entries = zip_entries(zip_data)
        expect(entries.first).to start_with("test-game-export-")
      end

      it "includes character files when characters exist", db: true do
        character = create(:character, game: game, user: player_user, name: "Aria")
        participant.update!(character: character)
        entries = zip_entries(GameExportService.new(gm_user, [ game ]).call)
        expect(entries).to include(a_string_matching(%r{characters/aria/current_sheet\.md$}))
      end








      it "includes version history files for characters", db: true do
        character = create(:character, game: game, user: player_user, name: "Versioned")
        participant.update!(character: character)
        # Character gets a snapshot on create; update triggers another version
        character.update!(content: "Updated sheet")
        zip_data2 = GameExportService.new(gm_user, [ game ]).call
        entries = zip_entries(zip_data2)
        version_entries = entries.select { |e| e.include?("version_history") }
        expect(version_entries.size).to be >= 2
      end
    end

    context "single game, active player" do
      subject(:zip_data) { GameExportService.new(player_user, [ game ]).call }

      it "includes the scene the player participates in", db: true do
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

      it "includes only scenes they participated in", db: true do
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

      it "uses all-games-export as root directory", db: true do
        entries = zip_entries(zip_data)
        expect(entries.first).to start_with("all-games-export-")
      end

      it "includes both games", db: true do
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
      it "disambiguates scenes with duplicate titles", db: true do
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
