# typed: true
# frozen_string_literal: true

require "yaml"
require_relative "invariants"

module PunditSymbolic
  # Loads the central invariant contract (config/policy_invariants.yml) and
  # enforces the BIJECTION that negates drift structurally:
  #
  #   for every policy, the set of predicates its declaration accounts for
  #   == the set of public encodable predicates the policy actually has.
  #
  # A public predicate with no declaration entry, or a declaration entry naming a
  # predicate that doesn't exist, is a hard error — so declaration and code
  # cannot drift apart for even one commit. "Accounted for" means: named by at
  # least one invariant, OR listed under `unconstrained` (a deliberate,
  # reviewed "no declared property" — visible, never silent).
  #
  # File shape:
  #   GamePolicy:
  #     invariants:
  #       - equivalent: [show?, view?]
  #       - no_status_blind_grant: write_access?
  #     unconstrained: [create?, destroy?, ...]
  class Declarations
    Result = Struct.new(:policy_name, :violations, :drift_errors, :missing, keyword_init: true) do
      # A policy with no declaration at all (needs a human to author one).
      def undeclared? = missing
      def ok? = !missing && drift_errors.empty? && violations.empty?
    end

    def self.load(path)
      new(YAML.safe_load_file(path) || {})
    end

    def initialize(raw)
      @raw = raw
    end

    def declared?(policy_name)
      @raw.key?(policy_name)
    end

    # Verify one policy source against its declaration. `formulas` is
    # name => Formula for every public encodable predicate.
    def verify(policy_name, formulas)
      unless declared?(policy_name)
        return Result.new(policy_name: policy_name, violations: [], drift_errors: [], missing: true)
      end

      declaration = @raw.fetch(policy_name) || {}
      invariants = Array(declaration["invariants"])
      unconstrained = Array(declaration["unconstrained"])

      drift = drift_errors(formulas.keys, invariants, unconstrained)
      violations = drift.empty? ? run_invariants(invariants, formulas) : []
      Result.new(policy_name: policy_name, violations: violations, drift_errors: drift, missing: false)
    end

    private

    # The bijection check. Returns human-readable drift errors; empty == in sync.
    def drift_errors(predicate_names, invariants, unconstrained)
      predicates = predicate_names.to_set
      referenced = invariants.flat_map { |entry| predicates_in(entry) }.to_set
      accounted = referenced | unconstrained.to_set

      errors = []
      (predicates - accounted).sort.each do |name|
        errors << "predicate `#{name}` has no declaration (add an invariant for it, or list it under `unconstrained`)"
      end
      (accounted - predicates).sort.each do |name|
        errors << "declaration references `#{name}`, which is not a public encodable predicate of this policy (stale entry)"
      end
      errors
    end

    def predicates_in(entry)
      _type, argument = Invariants.single_pair(entry)
      argument.is_a?(Array) ? argument : [ argument ]
    end

    def run_invariants(invariants, formulas)
      invariants.filter_map { |entry| Invariants.check(entry, formulas) }
    end
  end
end
