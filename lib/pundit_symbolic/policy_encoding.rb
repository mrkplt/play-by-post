# typed: true
# frozen_string_literal: true

require_relative "encoder"

module PunditSymbolic
  # Runs the Encoder over a policy's method defs, producing the raw formulas (with
  # `call:` delegation markers) and collecting refusals. Holds the encoder + the
  # two accumulators so the per-def work is a plain method, not a threaded call.
  class PolicyEncoding
    attr_reader :raw, :refusals

    def initialize(defs)
      @defs = defs
      @encoder = Encoder.new(defs.keys.map(&:to_s), path_helpers)
      @raw = {}
      @refusals = []
    end

    def run
      @defs.each { |name, info| encode(name.to_s, info) }
      self
    end

    private

    # Path helpers (non-predicate navigation methods like `def scene =
    # record.scene`) exist only to be inlined into predicates; they are not part
    # of the authorization surface, so they are neither encoded nor refused.
    def encode(name, info)
      node = info[:node]
      return if !name.end_with?("?") && @encoder.path_helper?(node)

      raw[name] = @encoder.encode(node)
    rescue Unencodable => error
      refusals << { name: name, public: info[:public], reason: error.reason }
    end

    # Non-predicate helper defs, by name -> DefNode, for the encoder to inline.
    def path_helpers
      @defs.reject { |name, _| name.to_s.end_with?("?") }
           .transform_values { |info| info[:node] }
    end
  end
end
