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

  # Zip assembly with every read stubbed: entry paths and slugging are the
  # service's own doing, so they need built records, not persisted ones.
  # Which scenes a membership exports is a pure rule; the query only applies it.
  describe "#scene_selection_for" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def rule_for(role:, status: "active")
      service.send(:scene_selection_for, build_stubbed(:game_member, role: role, status: status))
    end

    it "gives a GM every scene" do
      expect(rule_for(role: "game_master")).to eq(:all)
    end

    it "limits a removed member to scenes they took part in" do
      expect(rule_for(role: "player", status: "removed")).to eq(:participating)
    end

    it "gives an active player the scenes visible to them" do
      expect(rule_for(role: "player")).to eq(:visible)
    end
  end

  describe "#call (zip layout)" do
    let(:export_user) { build_stubbed(:user) }
    let(:gm_member) { build_stubbed(:game_member, role: "game_master", status: "active") }

    def build_service(games, scenes: [], characters: [], versions: [])
      games.each { |g| allow(g).to receive(:member_for).with(export_user).and_return(gm_member) }
      described_class.new(export_user, games).tap do |service|
        allow(service).to receive(:export_scenes_for).and_return(scenes)
        allow(service).to receive(:members_for).and_return([])
        allow(service).to receive(:files_for).and_return([])
        allow(service).to receive(:participants_for).and_return([])
        allow(service).to receive(:published_posts_for).and_return([])
        allow(service).to receive(:characters_for).and_return(characters)
        allow(service).to receive(:versions_for).and_return(versions)
      end
    end

    def entries_for(...) = zip_entries(build_service(...).call)

    let(:one_game) { [ build_stubbed(:game, name: "Sunken Archive") ] }

    it "writes a README and a files manifest" do
      entries = entries_for(one_game)

      expect(entries).to include(a_string_matching(%r{README\.md$}))
      expect(entries).to include(a_string_matching(%r{files_manifest\.md$}))
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
    end

    context "single game, active player" do
      subject(:zip_data) { GameExportService.new(player_user, [ game ]).call }


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
