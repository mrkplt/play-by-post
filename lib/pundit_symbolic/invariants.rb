# typed: true
# frozen_string_literal: true

require_relative "formula"
require_relative "solver"

module PunditSymbolic
  # The library of declarable invariant TYPES. Each type checks one property of a
  # policy's encoded predicate formulas over ALL inputs and returns a Violation
  # (with a counterexample) if it can fail. This is the whole vocabulary a
  # declaration in config/policy_invariants.yml may use; the tool checks exactly
  # what is declared.
  module Invariants
    Violation = Struct.new(:type, :description, :model, keyword_init: true)

    # Raised when a declaration names a missing predicate or an unknown type.
    class BadDeclaration < StandardError; end

    # Binds a policy's `formulas` once so each check reads as a property over
    # named predicates rather than threading (formulas, ...) everywhere.
    class Check
      def initialize(formulas)
        @formulas = formulas
      end

      def formula(name)
        @formulas.fetch(name) do
          Kernel.raise BadDeclaration, "invariant names `#{name}`, which is not an encodable predicate of this policy"
        end
      end

      # a and b agree on every input.
      def equivalent(pair)
        first, second = pair
        counterexample(xor(formula(first), formula(second))) do |model|
          violation("equivalent", "#{first} and #{second} are declared equivalent but disagree.", model)
        end
      end

      # first grants ⇒ second grants.
      def implies(pair)
        first, second = pair
        counterexample(Formula.conj(formula(first), Formula.negate(formula(second)))) do |model|
          violation("implies", "#{first} is declared to imply #{second}, but #{first} grants where #{second} denies.", model)
        end
      end

      # never both true.
      def mutually_exclusive(pair)
        first, second = pair
        counterexample(Formula.conj(formula(first), formula(second))) do |model|
          violation("mutually_exclusive", "#{first} and #{second} are declared mutually exclusive but can both hold.", model)
        end
      end

      # pred is constant true (expected) / false.
      def constant(name, expected)
        target = formula(name)
        counterexample(expected ? Formula.negate(target) : target) do |model|
          violation(expected ? "always" : "never", "#{name} is declared #{expected} for all inputs, but can be #{!expected}.", model)
        end
      end

      # pred must not grant via a membership's game_master role while ignoring
      # that membership's status (the multi-game-master leak).
      def no_status_blind_grant(name)
        StatusBlindGrant.new(formula(name), name).violation
      end

      private

      def counterexample(query)
        model = Solver.models_for(query).first
        model && yield(model)
      end

      def violation(type, description, model)
        Violation.new(type: type, description: description, model: model)
      end

      def xor(left, right)
        Formula.disj(Formula.conj(left, Formula.negate(right)), Formula.conj(right, Formula.negate(left)))
      end
    end

    # Detects the status-blind grant shape for one predicate's formula.
    class StatusBlindGrant
      ROLE_LEAF = /member_for\.game_master\?\z/

      def initialize(formula, name)
        @formula = formula
        @name = name
      end

      def violation
        role_leaf = @formula.variables.find { |leaf| leaf.match?(ROLE_LEAF) }
        return nil unless role_leaf && role_carries?(role_leaf)

        Violation.new(
          type: "no_status_blind_grant",
          description: "#{@name} grants via the game_master role without consulting that membership's status (breaks under multiple game masters).",
          model: Solver.models_for(grant_context(role_leaf)).first
        )
      end

      private

      # The role leaf alone flips the grant: grants with (role ∧ ¬active), denies
      # with (¬role ∧ ¬active).
      def role_carries?(role_leaf)
        Solver.sat?(grant_context(role_leaf)) &&
          !Solver.sat?(Formula.conj(@formula, Formula.conj(Formula.negate(role(role_leaf)), no_active(role_leaf))))
      end

      def grant_context(role_leaf)
        Formula.conj(@formula, Formula.conj(role(role_leaf), no_active(role_leaf)))
      end

      def role(role_leaf) = Formula.var(role_leaf)

      def no_active(role_leaf) = Formula.negate(Formula.var(role_leaf.sub("game_master?", "active?")))
    end

    # How each declared type invokes a Check. Keeps #check a table lookup rather
    # than a long dispatch.
    TYPES = {
      "equivalent" => ->(check, arg) { check.equivalent(arg) },
      "implies" => ->(check, arg) { check.implies(arg) },
      "mutually_exclusive" => ->(check, arg) { check.mutually_exclusive(arg) },
      "always" => ->(check, arg) { check.constant(arg, true) },
      "never" => ->(check, arg) { check.constant(arg, false) },
      "no_status_blind_grant" => ->(check, arg) { check.no_status_blind_grant(arg) }
    }.freeze

    module_function

    # Dispatch one declaration entry (a single-key mapping) to its type.
    def check(entry, formulas)
      type, argument = single_pair(entry)
      runner = TYPES.fetch(type) { Kernel.raise BadDeclaration, "unknown invariant type `#{type}`" }
      runner.call(Check.new(formulas), argument)
    end

    def single_pair(entry)
      Kernel.raise BadDeclaration, "each invariant must be a single-key mapping, got #{entry.inspect}" unless entry.is_a?(Hash) && entry.size == 1

      entry.first
    end
  end
end
