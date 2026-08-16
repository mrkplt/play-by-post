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

    # The game_master ROLE leaf of a membership, named `<path>.member_for.game_master?`
    # — the decomposition of `record[.game].member_for(user)&.game_master?`. Matching
    # this pattern (not a hardcoded var name) is how the verifier recognizes the
    # status-invariant shape across policies with different receiver paths.
    MEMBER_ROLE = /member_for\.game_master\?\z/

    def self.verify_file(path)
      new(PolicySource.load(path)).verify
    end

    # `equivalences` is a list of [name_a, name_b] pairs the policy documents as
    # asking "the same question" (e.g. show?/view?). The verifier proves each
    # pair actually agrees on every input, reporting a counterexample if not.
    def initialize(source, equivalences: [])
      @source = source
      @equivalences = equivalences
      @by_name = source.public_predicates.to_h { |p| [ p.name, p ] }
    end

    def verify
      { policy: @source.policy_name, findings: findings, refusals: @source.refusals }
    end

    private

    def findings
      grants_under_forbidden_status + broken_equivalences
    end

    # A predicate whose grant is LOAD-BEARING on the membership game_master ROLE
    # leaf, WITHOUT that same membership's status being consulted. Concretely:
    # the predicate reads `<path>.member_for.game_master?` and the role leaf
    # alone flips it from deny to grant (grants with role true even when the
    # active-status leaf is false; denies when role is false, statuses held
    # false). That grant is correct only under the unstated invariant that a
    # game_master's membership status cannot become removed/banned — the moment
    # multiple GMs make that invariant false, it leaks to a removed/banned GM.
    def grants_under_forbidden_status
      @by_name.values.filter_map do |predicate|
        role_leaf = predicate.formula.variables.find { |v| v.match?(MEMBER_ROLE) }
        next unless role_leaf

        # The active-status leaf paired with this role leaf (same member_for path).
        active_leaf = role_leaf.sub("game_master?", "active?")
        role = Formula.var(role_leaf)
        deny_ctx = Formula.negate(Formula.var(active_leaf))

        # role alone carries the grant: grants with (role ∧ ¬active),
        # denies with (¬role ∧ ¬active).
        role_grants = Solver.sat?(all_of(predicate.formula, role, deny_ctx))
        role_needed = !Solver.sat?(all_of(predicate.formula, Formula.negate(role), deny_ctx))
        next unless role_grants && role_needed

        Finding.new(
          kind: :role_grant_ignores_status,
          description: "#{predicate.name} grants via the game_master role of a membership without consulting that membership's status — safe only under the unstated invariant that a GM's membership status cannot change (breaks under multiple game masters).",
          model: Solver.models_for(all_of(predicate.formula, role, deny_ctx)).first
        )
      end
    end

    # Predicates the policy documents as "the same question" must agree on every
    # input. Report a counterexample where they diverge.
    def broken_equivalences
      @equivalences.filter_map do |(name_a, name_b)|
        # A documented-equivalent pair where one side was refused can't be
        # checked; skip rather than crash (the refusal is already reported).
        next unless @by_name.key?(name_a) && @by_name.key?(name_b)

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
