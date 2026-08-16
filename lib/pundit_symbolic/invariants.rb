# typed: true
# frozen_string_literal: true

require_relative "formula"
require_relative "solver"

module PunditSymbolic
  # The library of declarable invariant TYPES. Each type compiles a declaration
  # entry into a SAT query over a policy's encoded predicate formulas and reports
  # a violation (with a concrete counterexample) if the property can fail.
  #
  # This is the whole vocabulary a policy's declaration in config/policy_invariants.yml
  # may use. Nothing runs that a declaration does not ask for: the tool checks
  # EXACTLY the invariants declared, per policy.
  module Invariants
    Violation = Struct.new(:type, :description, :model, keyword_init: true)

    # Raised when a declaration names a predicate the policy doesn't (encodably)
    # have, or an unknown invariant type — a broken contract, surfaced loudly.
    class BadDeclaration < StandardError; end

    module_function

    # Dispatch one declaration entry to its type. `entry` is a Hash with one
    # type key, e.g. { "equivalent" => ["show?", "view?"] }.
    def check(entry, formulas)
      type, argument = single_pair(entry)
      case type
      when "equivalent" then equivalent(argument, formulas)
      when "implies" then implies(argument, formulas)
      when "mutually_exclusive" then mutually_exclusive(argument, formulas)
      when "always" then constant(argument, formulas, expected: true)
      when "never" then constant(argument, formulas, expected: false)
      when "no_status_blind_grant" then no_status_blind_grant(argument, formulas)
      else
        Kernel.raise BadDeclaration, "unknown invariant type `#{type}`"
      end
    end

    # `equivalent: [a, b]` — a and b agree on every input.
    def equivalent(pair, formulas)
      a = fetch(pair.fetch(0), formulas)
      b = fetch(pair.fetch(1), formulas)
      model = Solver.models_for(xor(a, b)).first
      return nil unless model

      Violation.new(
        type: "equivalent",
        description: "#{pair[0]} and #{pair[1]} are declared equivalent but disagree.",
        model: model
      )
    end

    # `implies: [a, b]` — whenever a grants, b grants (a ⇒ b).
    def implies(pair, formulas)
      a = fetch(pair.fetch(0), formulas)
      b = fetch(pair.fetch(1), formulas)
      # counterexample: a ∧ ¬b
      model = Solver.models_for(Formula.conj(a, Formula.negate(b))).first
      return nil unless model

      Violation.new(
        type: "implies",
        description: "#{pair[0]} is declared to imply #{pair[1]}, but #{pair[0]} grants where #{pair[1]} denies.",
        model: model
      )
    end

    # `mutually_exclusive: [a, b]` — never both true.
    def mutually_exclusive(pair, formulas)
      a = fetch(pair.fetch(0), formulas)
      b = fetch(pair.fetch(1), formulas)
      model = Solver.models_for(Formula.conj(a, b)).first
      return nil unless model

      Violation.new(
        type: "mutually_exclusive",
        description: "#{pair[0]} and #{pair[1]} are declared mutually exclusive but can both hold.",
        model: model
      )
    end

    # `always: pred` / `never: pred` — pred is constant true / false.
    def constant(name, formulas, expected:)
      formula = fetch(name, formulas)
      # violation: an assignment giving the opposite of expected.
      query = expected ? Formula.negate(formula) : formula
      model = Solver.models_for(query).first
      return nil unless model

      Violation.new(
        type: expected ? "always" : "never",
        description: "#{name} is declared to be #{expected} for all inputs, but can be #{!expected}.",
        model: model
      )
    end

    # `no_status_blind_grant: pred` — pred must not grant via a membership's
    # game_master role while ignoring that membership's status (the multi-GM
    # leak). Violated when the role leaf alone carries the grant.
    def no_status_blind_grant(name, formulas)
      formula = fetch(name, formulas)
      role_leaf = formula.variables.find { |v| v.match?(/member_for\.game_master\?\z/) }
      return nil unless role_leaf

      active_leaf = role_leaf.sub("game_master?", "active?")
      role = Formula.var(role_leaf)
      deny_ctx = Formula.negate(Formula.var(active_leaf))
      role_grants = Solver.sat?(all_of(formula, role, deny_ctx))
      role_needed = !Solver.sat?(all_of(formula, Formula.negate(role), deny_ctx))
      return nil unless role_grants && role_needed

      Violation.new(
        type: "no_status_blind_grant",
        description: "#{name} grants via the game_master role without consulting that membership's status (breaks under multiple game masters).",
        model: Solver.models_for(all_of(formula, role, deny_ctx)).first
      )
    end

    # --- helpers ---

    def single_pair(entry)
      Kernel.raise BadDeclaration, "each invariant must be a single-key mapping, got #{entry.inspect}" unless entry.is_a?(Hash) && entry.size == 1

      entry.first
    end

    def fetch(name, formulas)
      formulas.fetch(name) do
        Kernel.raise BadDeclaration, "invariant names `#{name}`, which is not an encodable predicate of this policy"
      end
    end

    def xor(a, b)
      Formula.disj(Formula.conj(a, Formula.negate(b)), Formula.conj(b, Formula.negate(a)))
    end

    def all_of(*nodes)
      nodes.reduce { |acc, node| Formula.conj(acc, node) }
    end
  end
end
