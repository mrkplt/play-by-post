# typed: true

module GameExport
  # A character's current sheet and each historical version. Both are a short
  # metadata header followed by the sheet body under a rule.
  module CharacterDocuments
    extend T::Sig

    BLANK = ""

    sig { params(character: Character).returns(String) }
    def self.sheet(character)
      body(
        title: "# #{character.name}",
        metadata: [
          "**Owner:** #{Author.name_for(character.user)}",
          "**Hidden:** #{character.hidden? ? "Yes" : "No"}",
          "**Archived:** #{character.archived? ? "Yes" : "No"}"
        ],
        content: character.content.to_s
      )
    end

    sig { params(version: CharacterVersion, number: Integer).returns(String) }
    def self.version(version, number)
      body(
        title: "# Version #{number} — #{version.created_at.strftime("%Y-%m-%d")}",
        metadata: [ "**Edited by:** #{Author.name_for(version.edited_by)}" ],
        content: version.content.to_s
      )
    end

    sig { params(title: String, metadata: T::Array[String], content: String).returns(String) }
    def self.body(title:, metadata:, content:)
      [ title, BLANK, *metadata, BLANK, "---", BLANK, content, BLANK ].join("\n")
    end
  end
end
