# typed: true

module GameExport
  # README.md at the root of a game's export: title, description, member table
  # and scene counts. Pure formatting — the member list is read by the caller
  # and handed in.
  module ReadmeDocument
    extend T::Sig

    BLANK = ""

    sig { params(game: Game, scenes: T::Array[Scene], members: T::Array[GameMember]).returns(String) }
    def self.call(game, scenes, members)
      [
        "# #{game.name}",
        BLANK,
        game.description.presence || "_No description._",
        BLANK,
        "**Exported:** #{Time.current.utc.strftime("%Y-%m-%d %H:%M UTC")}",
        BLANK,
        *member_lines(members),
        *scene_lines(scenes)
      ].join("\n")
    end

    sig { params(members: T::Array[GameMember]).returns(T::Array[String]) }
    def self.member_lines(members)
      [
        "## Members",
        BLANK,
        "| Display Name | Role | Status |",
        "|---|---|---|",
        *members.map { |member| member_row(member) },
        BLANK
      ]
    end

    sig { params(member: T.untyped).returns(String) }
    def self.member_row(member)
      role = member.game_master? ? "GM" : "Player"
      status = member.removed? ? "Former" : "Active"

      "| #{Author.name_for(member.user)} | #{role} | #{status} |"
    end

    sig { params(scenes: T::Array[Scene]).returns(T::Array[String]) }
    def self.scene_lines(scenes)
      [
        "## Scenes",
        BLANK,
        "- Active: #{scenes.count { |scene| !scene.resolved? }}",
        "- Resolved: #{scenes.count(&:resolved?)}",
        BLANK
      ]
    end
  end
end
