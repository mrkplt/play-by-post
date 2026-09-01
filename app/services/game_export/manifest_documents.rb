# typed: true

module GameExport
  # The two table-shaped manifests, files_manifest.md and links_manifest.md.
  # They share a shape — heading, empty-state sentence, table, footnote — so
  # they share a builder rather than repeating it twice.
  module ManifestDocuments
    extend T::Sig

    BLANK = ""

    # The fixed parts of each manifest — everything except the rows, which are
    # built per call.
    Layout = Struct.new(:heading, :empty, :header, :divider, :footnote)

    FILES = T.let(
      Layout.new(
        "# Game Files",
        "_No files uploaded._",
        "| Filename | Type | Size | Uploaded |",
        "|---|---|---|---|",
        "_The files themselves are in the `files/` folder of this export._"
      ).freeze,
      Layout
    )
    LINKS = T.let(
      Layout.new(
        "# Game Links",
        "_No links added._",
        "| Description | URL |",
        "|---|---|",
        "_External links open in a new tab._"
      ).freeze,
      Layout
    )

    sig { params(files: T::Array[GameFile]).returns(String) }
    def self.files(files)
      document(FILES, files.map { |game_file| file_row(game_file) })
    end

    sig { params(game_file: T.untyped).returns(String) }
    def self.file_row(game_file)
      size = game_file.file.attached? ? humanize_bytes(game_file.byte_size || 0) : "unknown"
      uploaded = game_file.created_at.strftime("%Y-%m-%d")

      "| #{game_file.filename} | #{game_file.content_type} | #{size} | #{uploaded} |"
    end

    sig { params(links: T::Array[GameLink]).returns(String) }
    def self.links(links)
      document(LINKS, links.map { |link| "| #{link.description} | #{link.url} |" })
    end

    sig { params(layout: Layout, rows: T::Array[String]).returns(String) }
    def self.document(layout, rows)
      body = if rows.empty?
        [ layout.empty ]
      else
        [ layout.header, layout.divider, *rows, BLANK, layout.footnote ]
      end

      [ layout.heading, BLANK, *body, BLANK ].join("\n")
    end

    sig { params(bytes: Integer).returns(String) }
    def self.humanize_bytes(bytes)
      if bytes >= 1_048_576
        "#{(bytes / 1_048_576.0).round(1)} MB"
      elsif bytes >= 1_024
        "#{(bytes / 1_024.0).round(1)} KB"
      else
        "#{bytes} B"
      end
    end
  end
end
