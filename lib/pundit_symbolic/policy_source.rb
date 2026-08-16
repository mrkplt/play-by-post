# typed: true
# frozen_string_literal: true

require "prism"
require_relative "method_defs"
require_relative "policy_encoding"
require_relative "delegation_resolver"

module PunditSymbolic
  # Loads one policy's source and produces its public predicates as formulas over
  # LEAF facts only (delegation resolved), plus the refusals. A thin orchestrator
  # over MethodDefs (parse), PolicyEncoding (encode), and DelegationResolver
  # (inline `call:` markers).
  class PolicySource
    Predicate = Struct.new(:name, :formula, :public, keyword_init: true) do
      def public? = public

      # A copy with a rewritten formula (used when cross-policy resolution rebases
      # the leaves) — keeps callers from re-reading name/public to rebuild one.
      def with_formula(new_formula)
        Predicate.new(name: name, formula: new_formula, public: public)
      end

      # The refusal record for this predicate, with the given reason.
      def refusal(reason)
        { name: name, public: public, reason: reason }
      end
    end

    attr_reader :predicates

    # Read externally (PolicyRegistry, the gate, the proof); plain readers rather
    # than attr_reader because the ivar-hygiene check only sees intra-file use.
    def policy_name = @policy_name
    def refusals = @refusals

    def self.load(path)
      new(path)
    end

    def initialize(path)
      class_node = find_policy_class(path)
      @policy_name = class_node.name.to_s
      defs = MethodDefs.extract(class_node)

      encoding = PolicyEncoding.new(defs).run
      @refusals = encoding.refusals
      @predicates = DelegationResolver.new(encoding.raw, defs, @refusals).call
    end

    # Public predicates only (the authorization surface). Refused methods are in
    # #refusals, keyed by name with a reason.
    def public_predicates
      predicates.select(&:public?)
    end

    private

    def find_policy_class(path)
      Prism.parse_file(path).value.statements.body.grep(Prism::ClassNode).first ||
        raise("no class definition in #{path}")
    end
  end
end
