# typed: true
# frozen_string_literal: true

require_relative "policy_source"
require_relative "solver"

module PunditSymbolic
  # Runs the consistency questions over a policy's encoded predicates and returns
  # findings (each with a concrete counterexample model) plus refusals.
  #
  # No domain axioms are assumed (the "explore the full space" choice): the
  # solver may reach states the app believes unreachable, e.g. a banned GM. Such
  # states are reported so a human triages "real bug" vs "unstated invariant"
  # rather than the tool silently deciding for them.
  class Verifier
    Finding = Struct.new(:kind, :description, :model, keyword_init: true)

    # The leaf facts and the app-belief that some combinations are unreachable.
    # Stated here ONLY to annotate findings, never asserted into the solver.
    STATUS_LEAVES = %w[member_gm member_active member_removed].freeze

    def self.verify_file(path)
      new(PolicySource.load(path)).verify
    end

    # `equivalences` is a list of [name_a, name_b] pairs the policy documents as
    # asking "the same question" (e.g. show?/view?). The verifier proves each
    # pair actually agrees on every input, reporting a counterexample if not.
    def initialize(source, equivalences: [])
      @source = source
      @equivalences = equivalences
      @by_name = source.public_predicates.to_h { |p| [p.name, p] }
    end

    def verify
      { policy: @source.policy_name, findings: findings, refusals: @source.refusals }
    end

    private

    def findings
      grants_under_forbidden_status + broken_equivalences
    end

    # A predicate whose grant is LOAD-BEARING on the membership-role leaf
    # (`member_gm`) reaching access together with a non-active status
    # (`member_removed`). "Load-bearing" = the predicate reads member_gm and can
    # be flipped from deny to grant purely by the member_gm ∧ member_removed
    # combination — the exact state the app believes unreachable because a GM's
    # membership status cannot change. If that invariant ever breaks, this is the
    # grant that leaks. Trivial predicates (`true`, pure `gm`) don't qualify:
    # they don't read the membership leaf, so no status invariant protects them.
    def grants_under_forbidden_status
      @by_name.values.filter_map do |predicate|
        next unless predicate.formula.variables.include?("member_gm")

        base = Formula.var("member_gm")
        removed = Formula.var("member_removed")
        # Grant holds with (member_gm ∧ member_removed) ...
        with_removed = Solver.sat?(all_of(predicate.formula, base, removed))
        # ... and the member_gm path is what carries it (deny when NOT member_gm,
        # holding member_active false so only the role leaf differs).
        role_carries = Solver.sat?(all_of(predicate.formula, base, Formula.negate(Formula.var("member_active")))) &&
          !Solver.sat?(all_of(predicate.formula, Formula.negate(base), Formula.negate(Formula.var("member_active"))))
        next unless with_removed && role_carries

        Finding.new(
          kind: :role_grant_ignores_status,
          description: "#{predicate.name} grants to a member via the game_master role leaf regardless of a removed/banned status — safe only under the unstated invariant that a GM's membership status cannot change.",
          model: Solver.models_for(all_of(predicate.formula, base, removed)).first
        )
      end
    end

    # Predicates the policy documents as "the same question" must agree on every
    # input. Report a counterexample where they diverge.
    def broken_equivalences
      @equivalences.filter_map do |(name_a, name_b)|
        a = @by_name.fetch(name_a).formula
        b = @by_name.fetch(name_b).formula
        # SAT( a XOR b ) — an input where they disagree.
        xor = Formula.disj(all_of(a, Formula.negate(b)), all_of(b, Formula.negate(a)))
        model = Solver.models_for(xor).first
        next unless model

        Finding.new(
          kind: :broken_equivalence,
          description: "#{name_a} and #{name_b} are documented as the same question but disagree.",
          model: model
        )
      end
    end

    def all_of(*nodes)
      nodes.reduce { |acc, node| Formula.conj(acc, node) }
    end
  end
end
