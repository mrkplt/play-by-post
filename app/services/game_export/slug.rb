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
  end
end
