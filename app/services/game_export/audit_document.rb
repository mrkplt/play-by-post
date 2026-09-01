# typed: true

require "csv"

module GameExport
  # The AI-generation audit trail as a CSV: one row per AiGeneration, resolving
  # the requester/funder ids to display names via a caller-supplied id->name map
  # (so the builder stays a pure function and does no lookups of its own). Header
  # is always written, so a GM export with no AI spend still gets a predictable,
  # empty-but-labelled file.
  module AuditDocument
    extend T::Sig

    HEADERS = T.let(
      %w[generated_at feature asset model_used requested_by funded_by input_tokens output_tokens cost].freeze,
      T::Array[String]
    )

    sig { params(generations: T::Array[AiGeneration], names: T::Hash[Integer, String]).returns(String) }
    def self.csv(generations, names)
      lines = [ HEADERS ] + generations.map { |generation| row(generation, names) }
      lines.map { |line| CSV.generate_line(line) }.join
    end

    sig { params(generation: AiGeneration, names: T::Hash[Integer, String]).returns(T::Array[T.untyped]) }
    def self.row(generation, names)
      [
        generation.created_at.utc.iso8601,
        generation.feature,
        "#{generation.asset_type}##{generation.asset_id}",
        generation.model_used,
        names[generation.requested_by_id],
        names[generation.funded_by_id],
        generation.input_tokens,
        generation.output_tokens,
        generation.cost
      ]
    end
  end
end
