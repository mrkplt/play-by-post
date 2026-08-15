require "rails_helper"

RSpec.describe GameExport::ReadmeDocument, :db do
  describe "#readme_content" do
    let(:exported_game) { build_stubbed(:game, name: "Test Game", description: "A test game.") }
    let(:service) { described_class.new(build_stubbed(:user), [ exported_game ]) }

    def member(display_name:, role: "player", status: "active")
      user = build_stubbed(:user)
      allow(user).to receive(:display_name).and_return(display_name)
      build_stubbed(:game_member, user: user, role: role, status: status, game: exported_game)
    end

    def readme(members: [], scenes: [])
      GameExport::ReadmeDocument.call(exported_game, scenes, members)
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
end
