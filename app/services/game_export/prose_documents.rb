# typed: true

module GameExport
  # The two single-body documents: a game Page and a notebook entry. Both are
  # a title, an optional metadata line, and a markdown body that falls back to
  # an empty-state sentence.
  module ProseDocuments
    extend T::Sig

    BLANK = ""

    sig { params(page: Page).returns(String) }
    def self.page(page)
      document(title: page.title, metadata: nil, body: page.body)
    end

    sig { params(entry: NotebookEntry).returns(String) }
    def self.notebook_entry(entry)
      document(title: entry.title, metadata: "**Status:** #{entry.status}", body: entry.body)
    end

    # A single historical version of a page or notebook entry — the title and
    # body as they stood at that revision, headed by its number/date and editor.
    # Page and notebook versions share the same title/body/edited_by shape, so
    # one renderer serves both.
    sig { params(version: T.untyped, number: Integer).returns(String) }
    def self.version(version, number)
      document(
        title: "Version #{number} — #{version.created_at.strftime("%Y-%m-%d")}",
        metadata: "**Edited by:** #{Author.name_for(version.edited_by)}\n\n**Title:** #{version.title}",
        body: version.body
      )
    end

    sig { params(title: String, metadata: T.nilable(String), body: T.nilable(String)).returns(String) }
    def self.document(title:, metadata:, body:)
      metadata_lines = metadata ? [ metadata, BLANK ] : []

      [ "# #{title}", BLANK, *metadata_lines, body.presence || "_No content._", BLANK ].join("\n")
    end
  end
end
