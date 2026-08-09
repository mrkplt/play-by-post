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
        return zip.read.force_encoding(Encoding::UTF_8) if entry.name == name
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

    # Exact-content pin — every literal, header and blank line in one assertion,
    # so a mutation to any of them (not just the fragments above) fails.
    it "renders the full document byte for byte" do
      Timecop.freeze(Time.utc(2026, 6, 15, 9, 30)) do
        content = readme(
          members: [
            member(display_name: "Dana", role: "game_master"),
            member(display_name: "Gus", status: "removed")
          ],
          scenes: [ build_stubbed(:scene), build_stubbed(:scene, :resolved) ]
        )

        expected = [
          "# Test Game",
          "",
          "A test game.",
          "",
          "**Exported:** 2026-06-15 09:30 UTC",
          "",
          "## Members",
          "",
          "| Display Name | Role | Status |",
          "|---|---|---|",
          "| Dana | GM | Active |",
          "| Gus | Player | Former |",
          "",
          "## Scenes",
          "",
          "- Active: 1",
          "- Resolved: 1",
          ""
        ].join("\n")

        expect(content).to eq(expected)
      end
    end
  end

  # posts.md and files_manifest.md are string building over a list. Stub the one
  # read each needs and they exercise every branch without a persisted graph or
  # a zip round-trip.
  describe "#posts_content" do
    let(:exported_scene) { build_stubbed(:scene) }
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def post_double(content: "Hello world!", author: "Alice", ooc: false, edited: nil, created_at: Time.utc(2026, 1, 1, 12, 0))
      double(
        user: double(display_name: author, email: "alice@example.com"),
        created_at: created_at,
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

    it "renders every post exactly, in order, separated by a rule" do
      posts = [
        post_double(content: "Hello world!", author: "Alice", created_at: Time.utc(2026, 1, 1, 12, 0)),
        post_double(content: "Random chatter", author: "Bob", ooc: true, edited: Time.utc(2026, 1, 2),
                     created_at: Time.utc(2026, 1, 2, 9, 30))
      ]

      expected = [
        "## Alice — 2026-01-01 12:00 UTC",
        "",
        "Hello world!",
        "",
        "---",
        "",
        "## Bob — 2026-01-02 09:30 UTC (edited)",
        "[Out of Character]",
        "",
        "Random chatter",
        "",
        "---",
        ""
      ].join("\n")

      expect(posts_md(posts)).to eq(expected)
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

    it "renders the full document byte for byte with files" do
      expected = [
        "# Game Files",
        "",
        "| Filename | Type | Size | Uploaded |",
        "|---|---|---|---|",
        "| rules.pdf | application/pdf | 500 B | 2026-01-01 |",
        "",
        "_Binary files are not included in this export. The game's GM can download them from the app._",
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
      allow(service).to receive(:links_for).with(exported_game).and_return(links)
      service.send(:links_manifest_content, exported_game)
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

    it "renders the full document byte for byte, every section present" do
      parent = build_stubbed(:scene, title: "The Tavern")
      scene = build_stubbed(:scene, :resolved,
        title: "The Sunken Archive",
        description: "A drowned library.",
        created_at: Time.utc(2026, 1, 2),
        resolved_at: Time.utc(2026, 1, 10),
        resolution: "The archive was recovered.",
        parent_scene: parent)

      character = build_stubbed(:character, name: "Aria")
      dana = build_stubbed(:user)
      allow(dana).to receive(:display_name).and_return("Dana")
      sp_with_character = build_stubbed(:scene_participant, user: dana, character: character)

      gus = build_stubbed(:user)
      allow(gus).to receive(:display_name).and_return("Gus")
      sp_without_character = build_stubbed(:scene_participant, user: gus, character: nil)

      expected = [
        "# The Sunken Archive",
        "",
        "A drowned library.",
        "",
        "**Status:** Resolved",
        "**Created:** 2026-01-02",
        "**Resolved:** 2026-01-10",
        "",
        "## Parent Scene",
        "",
        "The Tavern",
        "",
        "## Participants",
        "",
        "| Display Name | Character |",
        "|---|---|",
        "| Dana | Aria |",
        "| Gus | — |",
        "",
        "## Resolution",
        "",
        "The archive was recovered.",
        ""
      ].join("\n")

      expect(info(scene, participants: [ sp_with_character, sp_without_character ])).to eq(expected)
    end

    it "renders the full document byte for byte, every optional section absent" do
      scene = build_stubbed(:scene,
        title: "First Contact",
        description: "",
        created_at: Time.utc(2026, 2, 3),
        parent_scene: nil)

      expected = [
        "# First Contact",
        "",
        "_No description._",
        "",
        "**Status:** Active",
        "**Created:** 2026-02-03",
        ""
      ].join("\n")

      expect(info(scene, participants: [])).to eq(expected)
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

  describe "#page_content" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def content(page)
      service.send(:page_content, page)
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
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def content(entry)
      service.send(:notebook_entry_content, entry)
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
  # The reads are stubbed everywhere above, so nothing else executes their query
  # chains — cover them directly or every mutation of them survives.
  describe "reads" do
    let(:service) { described_class.new(reader, []) }
    let(:reader) { build_stubbed(:user) }

    def chain
      double.tap do |c|
        allow(c).to receive(:includes).and_return(c)
        allow(c).to receive(:order).and_return(c)
        allow(c).to receive(:joins).and_return(c)
        allow(c).to receive(:where).and_return(c)
        allow(c).to receive(:not).and_return(c)
        allow(c).to receive(:to_a).and_return([])
      end
    end

    it "loads members with their user, ordered by role then status" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_members).and_return(c)

      service.send(:members_for, game)

      expect(c).to have_received(:includes).with(:user)
      expect(c).to have_received(:order).with(:role, :status)
    end

    it "loads files with their blob, ordered by filename" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_files).and_return(c)

      service.send(:files_for, game)

      expect(c).to have_received(:includes).with(file_attachment: :blob)
      expect(c).to have_received(:order).with(:filename)
    end

    it "loads pages ordered by title" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:pages).and_return(c)

      service.send(:pages_for, game)

      expect(c).to have_received(:order).with(:title)
    end

    it "loads notebook entries ordered by title" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:notebook_entries).and_return(c)

      service.send(:notebook_entries_for, game)

      expect(c).to have_received(:order).with(:title)
    end

    it "loads links ordered by description" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_links).and_return(c)

      service.send(:links_for, game)

      expect(c).to have_received(:order).with(:description)
    end

    it "loads participants with their user and character" do
      scene = build_stubbed(:scene)
      c = chain
      allow(scene).to receive(:scene_participants).and_return(c)

      service.send(:participants_for, scene)

      expect(c).to have_received(:includes).with(:user, :character)
    end

    it "loads published posts with their user, oldest first" do
      scene = build_stubbed(:scene)
      c = chain
      allow(scene).to receive(:posts).and_return(double(published: c))

      service.send(:published_posts_for, scene)

      expect(c).to have_received(:includes).with(:user)
      expect(c).to have_received(:order).with(:created_at)
    end

    it "loads versions with their editor, oldest first" do
      character = build_stubbed(:character)
      c = chain
      allow(character).to receive(:character_versions).and_return(c)

      service.send(:versions_for, character)

      expect(c).to have_received(:includes).with(:edited_by)
      expect(c).to have_received(:order).with(:created_at)
    end

    describe "#characters_for" do
      let(:export_game) { build_stubbed(:game) }
      let(:export_scene) { build_stubbed(:scene) }

      before do
        participants = chain
        allow(participants).to receive(:pluck).and_return([ 7 ])
        allow(SceneParticipant).to receive(:where).and_return(participants)

        owned = chain
        allow(owned).to receive(:pluck).and_return([ 9 ])
        allow(export_game).to receive(:characters).and_return(double(where: owned))

        @found = chain
        allow(Character).to receive(:where).and_return(@found)
      end

      it "combines participant characters with the viewer's own, deduped and ordered" do
        service.send(:characters_for, export_game, [ export_scene ])

        expect(Character).to have_received(:where).with(id: [ 7, 9 ])
        expect(@found).to have_received(:includes).with(:user, :character_versions)
        expect(@found).to have_received(:order).with(:name)
      end

      it "ignores participants with no character" do
        service.send(:characters_for, export_game, [ export_scene ])

        expect(SceneParticipant).to have_received(:where).with(scene_id: [ export_scene.id ])
      end
    end
  end

  # Which membership gets which scenes is exactly what the query has to select
  # on: a real, persisted graph is needed so a wrong join, where clause, or
  # branch actually changes what comes back — a stubbed relation can't fail
  # this the way a real one does.
  describe "#export_scenes_for" do
    let(:service) { described_class.new(player_user, [ game ]) }

    it "gives the GM every scene in the game, including private ones" do
      secret = create(:scene, :private, game: game, title: "Secret Room")

      result = described_class.new(gm_user, [ game ]).send(:export_scenes_for, game, :all)

      expect(result).to contain_exactly(scene, secret)
    end

    it "limits a removed member to scenes they participated in" do
      removed_user = create(:user, :with_profile)
      removed_member = create(:game_member, :removed, game: game, user: removed_user)
      create(:scene_participant, scene: scene, user: removed_user)
      elsewhere = create(:scene, game: game, title: "Elsewhere")

      result = described_class.new(removed_user, [ game ]).send(:export_scenes_for, game, :participating)

      expect(result).to contain_exactly(scene)
      expect(result).not_to include(elsewhere)
    end

    it "gives an active player the scenes visible to them, not private ones they're not in" do
      create(:scene, :private, game: game, title: "Secret Room")

      result = service.send(:export_scenes_for, game, :visible)

      expect(result).to contain_exactly(scene)
    end

    it "scopes visible scenes to the requested game, not every game the viewer can see" do
      other_game = create(:game, name: "Other Game")
      create(:game_member, game: other_game, user: player_user, role: "player", status: "active")
      create(:scene, game: other_game, title: "Elsewhere Entirely")

      result = service.send(:export_scenes_for, game, :visible)

      expect(result).to contain_exactly(scene)
    end
  end

  describe "#call (zip layout)" do
    let(:export_user) { build_stubbed(:user) }
    let(:gm_member) { build_stubbed(:game_member, role: "game_master", status: "active") }

    def build_service(games, scenes: [], characters: [], versions: [], pages: [], notebook_entries: [], gm: true)
      games.each do |g|
        allow(g).to receive(:member_for).with(export_user).and_return(gm_member)
        allow(g).to receive(:game_master?).with(export_user).and_return(gm)
      end
      described_class.new(export_user, games).tap do |service|
        allow(service).to receive(:export_scenes_for).and_return(scenes)
        allow(service).to receive(:members_for).and_return([])
        allow(service).to receive(:files_for).and_return([])
        allow(service).to receive(:links_for).and_return([])
        allow(service).to receive(:participants_for).and_return([])
        allow(service).to receive(:published_posts_for).and_return([])
        allow(service).to receive(:characters_for).and_return(characters)
        allow(service).to receive(:versions_for).and_return(versions)
        allow(service).to receive(:pages_for).and_return(pages)
        allow(service).to receive(:notebook_entries_for).and_return(notebook_entries)
      end
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

        expect(zip_file_content(zip_data, name)).to eq(service.send(:readme_content, one_game.first, []))
      end

      it "writes the files manifest's own content under files_manifest.md" do
        service = build_service(one_game)
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("files_manifest.md") }

        expect(zip_file_content(zip_data, name)).to eq(service.send(:files_manifest_content, one_game.first))
      end

      it "writes the links manifest's own content under links_manifest.md" do
        service = build_service(one_game)
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("links_manifest.md") }

        expect(zip_file_content(zip_data, name)).to eq(service.send(:links_manifest_content, one_game.first))
      end

      it "writes each scene's own info and posts content" do
        service = build_service(one_game, scenes: [ one_scene ])
        zip_data = service.call
        info_name = zip_entries(zip_data).find { |e| e.end_with?("scene_info.md") }
        posts_name = zip_entries(zip_data).find { |e| e.end_with?("posts.md") }

        expect(zip_file_content(zip_data, info_name)).to eq(service.send(:scene_info_content, one_scene))
        expect(zip_file_content(zip_data, posts_name)).to eq(service.send(:posts_content, one_scene))
      end

      it "writes each character's own sheet and version content" do
        service = build_service(one_game, characters: [ one_character ], versions: [ one_version ])
        zip_data = service.call
        sheet_name = zip_entries(zip_data).find { |e| e.end_with?("current_sheet.md") }
        version_name = zip_entries(zip_data).find { |e| e.include?("version_history/") }

        expect(zip_file_content(zip_data, sheet_name)).to eq(service.send(:character_sheet_content, one_character))
        expect(zip_file_content(zip_data, version_name)).to eq(service.send(:character_version_content, one_version, 1))
      end

      it "writes each page's own content under pages/{slug}.md" do
        one_page = build_stubbed(:page, title: "House Rules")
        service = build_service(one_game, pages: [ one_page ])
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("house-rules.md") }

        expect(zip_file_content(zip_data, name)).to eq(service.send(:page_content, one_page))
      end

      it "writes each notebook entry's own content under notebook/{slug}.md" do
        one_entry = build_stubbed(:notebook_entry, title: "Wandering Merchant")
        service = build_service(one_game, gm: true, notebook_entries: [ one_entry ])
        zip_data = service.call
        name = zip_entries(zip_data).find { |e| e.end_with?("wandering-merchant.md") }

        expect(zip_file_content(zip_data, name)).to eq(service.send(:notebook_entry_content, one_entry))
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

      it "includes the game's notebook entries under notebook/" do
        create(:notebook_entry, game: game, title: "Wandering Merchant")
        entries = zip_entries(zip_data)
        expect(entries).to include(a_string_matching(%r{notebook/wandering-merchant\.md$}))
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
