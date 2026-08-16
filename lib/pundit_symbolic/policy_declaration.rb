# typed: true
# frozen_string_literal: true

require_relative "invariants"

module PunditSymbolic
  # One policy's declared contract: its invariant entries and its `unconstrained`
  # list. Answers the two questions the gate asks — does it drift from the code's
  # predicates, and do its invariants hold.
  class PolicyDeclaration
    def initialize(entry)
      @invariants = Array(entry["invariants"])
      @unconstrained = Array(entry["unconstrained"])
    end

    # Check this declaration against `formulas` (name => Formula): returns
    # [drift_errors, violations]. Violations are only computed when there is no
    # drift (a stale/missing predicate makes invariant results meaningless).
    def check(formulas)
      drift = drift_errors(formulas.keys)
      [ drift, drift.empty? ? violations(formulas) : [] ]
    end

    # Bijection check against the policy's actual predicate names. Empty == in
    # sync; otherwise one human-readable error per unaccounted or stale name.
    def drift_errors(predicate_names)
      predicates = predicate_names.to_set
      undeclared(predicates) + stale(predicates)
    end

    # Run each declared invariant against `formulas`; collect the violations.
    def violations(formulas)
      @invariants.filter_map { |entry| Invariants.check(entry, formulas) }
    end

    private

    def undeclared(predicates)
      (predicates - accounted).sort.map do |name|
        "predicate `#{name}` has no declaration (add an invariant for it, or list it under `unconstrained`)"
      end
    end

    def stale(predicates)
      (accounted - predicates).sort.map do |name|
        "declaration references `#{name}`, which is not a public encodable predicate of this policy (stale entry)"
      end
    end

    # Every predicate the declaration speaks to: those named by an invariant, plus
    # the explicitly-unconstrained ones.
    def accounted
      referenced = @invariants.flat_map { |entry| predicates_in(entry) }.to_set
      referenced | @unconstrained.to_set
    end

    def predicates_in(entry)
      _type, argument = Invariants.single_pair(entry)
      argument.is_a?(Array) ? argument : [ argument ]
    end
  end
end
