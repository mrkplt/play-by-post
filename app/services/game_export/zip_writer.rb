# typed: true

require "zip"

module GameExport
  # The low-level zip mechanics for an export: prefixing every entry with the
  # game's root, streaming a blob in chunks, slug-based de-duplication, and the
  # numbered version-history layout. Archive owns *what* goes in the zip; this
  # owns *how* each entry is written. One instance per game, so the zip and
  # prefix are state rather than threaded arguments.
  class ZipWriter
    extend T::Sig

    sig { params(zip: Zip::OutputStream, prefix: String).void }
    def initialize(zip, prefix)
      @zip = zip
      @prefix = prefix
    end

    sig { params(path: String, content: String).void }
    def entry(path, content)
      @zip.put_next_entry("#{@prefix}#{path}")
      @zip.write(content)
    end

    # Streams a blob's bytes into a zip entry in chunks, so a large attachment
    # never sits fully in memory. download's block form yields successive chunks
    # from the storage service.
    sig { params(path: String, blob: T.untyped).void }
    def blob_entry(path, blob)
      @zip.put_next_entry("#{@prefix}#{path}")
      blob.download { |chunk| @zip.write(chunk) }
    end

    # One tracker per collection, so repeated titles get -2/-3 rather than
    # colliding on the same path.
    sig do
      params(
        records: T::Array[T.untyped],
        name: Symbol,
        block: T.proc.params(record: T.untyped, slug: String).void
      ).void
    end
    def each_slugged(records, name, &block)
      tracker = T.let({}, T::Hash[String, Integer])
      records.each do |record|
        block.call(record, Slug.unique(Slug.call(record.public_send(name)), tracker))
      end
    end

    # Writes each retained version of a versioned record under
    # <base_dir>/version_history/vNNN-<date>.md, numbered oldest-first. The
    # renderer turns a version row into its markdown — the one thing that differs
    # between characters, pages and notebook entries.
    sig do
      params(
        base_dir: String,
        versions: T::Array[T.untyped],
        renderer: T.proc.params(version: T.untyped, number: Integer).returns(String)
      ).void
    end
    def version_history(base_dir, versions, &renderer)
      versions.each_with_index do |version, index|
        number = index + 1
        date = version.created_at.strftime("%Y-%m-%d")
        path = "#{base_dir}/version_history/#{format("v%03d", number)}-#{date}.md"

        entry(path, renderer.call(version, number))
      end
    end
  end
end
