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

    sig { params(title: String, metadata: T.nilable(String), body: T.nilable(String)).returns(String) }
    def self.document(title:, metadata:, body:)
      metadata_lines = metadata ? [ metadata, BLANK ] : []

      [ "# #{title}", BLANK, *metadata_lines, body.presence || "_No content._", BLANK ].join("\n")
    end
  end
end
