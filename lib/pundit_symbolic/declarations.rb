# typed: true
# frozen_string_literal: true

require "yaml"
require_relative "invariants"
require_relative "policy_declaration"

module PunditSymbolic
  # Loads the central invariant contract (config/policy_invariants.yml) and, per
  # policy, enforces the BIJECTION that negates drift structurally: every public
  # predicate must be accounted for by its declaration (named by an invariant, or
  # listed `unconstrained`), and no declaration may name a predicate that doesn't
  # exist. A policy with no entry is `missing` (a human must author it). The
  # per-policy work lives in PolicyDeclaration; this class is the file + lookup.
  #
  # File shape:
  #   GamePolicy:
  #     invariants:
  #       - equivalent: [show?, view?]
  #     unconstrained: [create?]
  class Declarations
    Result = Struct.new(:policy_name, :violations, :drift_errors, :missing, keyword_init: true) do
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

    # Verify one policy's public predicates (`formulas`: name => Formula) against
    # its declaration.
    def verify(policy_name, formulas)
      return missing_result(policy_name) unless declared?(policy_name)

      drift, violations = PolicyDeclaration.new(@raw.fetch(policy_name) || {}).check(formulas)
      Result.new(policy_name: policy_name, violations: violations, drift_errors: drift, missing: false)
    end

    private

    def missing_result(policy_name)
      Result.new(policy_name: policy_name, violations: [], drift_errors: [], missing: true)
    end
  end
end
