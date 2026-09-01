# typed: true

module GameExport
  # Filename-safe slugs for export directories. Titles are user-supplied and
  # may collide or reduce to nothing, so `unique` disambiguates repeats against
  # a caller-held tracker and `call` falls back to "untitled".
  module Slug
    extend T::Sig

    sig { params(text: String).returns(String) }
    def self.call(text)
      text.downcase
          .gsub(/[^a-z0-9\s-]/, "")
          .gsub(/\s+/, "-")
          .gsub(/-+/, "-")
          .strip
          .gsub(/\A-+|-+\z/, "")
          .then { |slug| slug.empty? ? "untitled" : slug }
    end

    sig { params(base: String, tracker: T::Hash[String, Integer]).returns(String) }
    def self.unique(base, tracker)
      seen = tracker[base].to_i
      ordinal = seen + 1
      tracker[base] = ordinal
      seen.zero? ? base : "#{base}-#{ordinal}"
    end

    # A filename-safe, de-duplicated slug that preserves the extension: the
    # extension is split off, the stem slugged (so "My Map.PDF" -> "my-map.pdf")
    # and de-duplicated against a caller-held tracker, with the ordinal inserted
    # before the extension so repeats read as "notes-2.txt", not "notes.txt-2".
    # A file with no extension keeps just its (de-duplicated) slugged stem. The
    # tracker is keyed by slugged stem, so two files that differ only in
    # extension case (Notes.TXT / notes.txt) still disambiguate.
    sig { params(name: String, tracker: T::Hash[String, Integer]).returns(String) }
    def self.unique_filename(name, tracker)
      ext = File.extname(name)
      deduped = unique(call(File.basename(name, ext)), tracker)
      ext.empty? ? deduped : "#{deduped}#{ext.downcase}"
    end
  end
end
