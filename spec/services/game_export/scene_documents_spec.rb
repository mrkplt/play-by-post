require "rails_helper"

RSpec.describe GameExport::SceneDocuments, :db do
  describe "#scene_info_content" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def info(scene, participants: [])
      GameExport::SceneDocuments.info(scene, participants)
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
      GameExport::SceneDocuments.posts(posts)
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
end
