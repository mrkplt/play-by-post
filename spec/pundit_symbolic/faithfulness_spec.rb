# typed: false
# frozen_string_literal: true

require_relative "spec_helper"
require "pundit_symbolic/policy_source"
require "pundit_symbolic/solver"

# The proof that the tool is trustworthy.
#
# The encoder turns a policy method into a boolean formula over leaf facts. The
# solver decides properties of that formula. The whole edifice is sound ONLY IF
# the formula means the same thing as the real Ruby method — i.e.
#
#     ∀ inputs i,  encode(m).eval(i) == m.call(i)
#
# The leaf-fact domain is finite and tiny, so we discharge that ∀ by EXHAUSTIVE
# enumeration: for every assignment of a predicate's leaf facts we build a real
# policy whose world matches the assignment, call the real method, and assert it
# equals the formula. Total enumeration over a finite domain is a proof, not a
# sample — this is the tool's `by decide`.
#
# The double is GENERIC: a leaf var name IS a canonical read path
# (`record.game.member_for.game_master?`), so a single proxy that interprets any
# such path against the assignment stands in for every policy's record. That is
# what lets the same proof cover all policies. Runs without booting Rails
# (policies are pure (user, record) objects).
RSpec.describe "PunditSymbolic encoder faithfulness", type: :model do
  # Interprets a leaf's read path against a boolean assignment. Navigation calls
  # (`.game`, `.member_for`) return a deeper proxy; predicate calls (`.game_master?`)
  # resolve to the assignment. `member_for` returns nil when the whole membership
  # is absent, so the real code's `membership&.x` safe-nav collapses to false —
  # exactly as the encoder models it.
  class RecordProxy
    # `reads` is a shared Set the whole proxy tree records boolean leaf reads
    # into, so a test can assert the formula mentions every leaf the real method
    # actually consulted (catching a dropped variable even if no other predicate
    # reads it).
    def initialize(assignment, path, reads = Set.new)
      @assignment = assignment
      @path = path # e.g. "record." or "record.game.member_for."
      @reads = reads
    end

    def method_missing(name, *_args)
      leaf = "#{@path}#{name}"
      if name.to_s.end_with?("?")
        # A boolean leaf read: record it and look it up (absent => false).
        @reads << leaf
        @assignment.fetch(leaf, false)
      elsif name == :member_for
        # Membership navigation: nil when no member_* leaf under this path is set,
        # so `&.` yields false for every status/role predicate.
        base = "#{leaf}."
        any = @assignment.keys.any? { |k| k.start_with?(base) && @assignment[k] }
        any ? RecordProxy.new(@assignment, base, @reads) : nil
      else
        # Plain association navigation (`.game`, `.scene`, `.character`).
        RecordProxy.new(@assignment, "#{leaf}.", @reads)
      end
    end

    def respond_to_missing?(_name, _include_private = false) = true
  end

  ALL_POLICIES = Dir[File.expand_path("../../app/policies/*_policy.rb", __dir__)]
    .reject { |p| p.end_with?("application_policy.rb") }
    .sort

  ALL_POLICIES.each do |path|
    context File.basename(path) do
      let(:source) { PunditSymbolic::PolicySource.load(path) }
      let(:policy_class) { Object.const_get(source.policy_name) }

      it "accounts for every public method (encoded or explicitly refused)" do
        real_publics = policy_class.instance_methods(false).map(&:to_s)
        # Field-authz methods are intentionally neither encoded nor refused.
        field_authz = %w[permitted_attributes permitted_attributes_for_create permitted_attributes_for_update]
        accounted = source.public_predicates.map(&:name) + source.refusals.map { |r| r[:name] } + field_authz

        expect(accounted.sort).to include(*real_publics.sort)
      end

      # THE PROOF: exhaustive differential equivalence, per encodable predicate.
      it "produces formulas that agree with the real methods on EVERY input" do
        # Enumerate over the union of leaf vars across the whole policy, EXPANDED
        # so that for every membership base (`<path>.member_for.`) the enumeration
        # varies all four status/role leaves — even ones no formula kept. This
        # defeats the short-circuit blind spot: the real method's `membership&.a? ||
        # membership&.b?` only reads b? when a? is false, so if the encoder DROPS
        # b?, nothing in a formula-derived var set would ever create the state that
        # reads it. Forcing all four statuses makes such a drop diverge.
        formula_vars = source.public_predicates.flat_map { |p| p.formula.variables.to_a }.uniq
        member_bases = formula_vars.filter_map { |v| v[/\A.*member_for\./] }.uniq
        expanded = member_bases.flat_map { |base| %w[game_master? active? removed? banned?].map { |s| "#{base}#{s}" } }
        all_vars = (formula_vars + expanded).uniq

        source.public_predicates.each do |predicate|
          reads = Set.new
          mismatches = PunditSymbolic::Solver.assignments(all_vars).filter_map do |assignment|
            user = RecordProxy.new(assignment, "user.", reads)
            record = RecordProxy.new(assignment, "record.", reads)
            real = policy_class.new(user, record).public_send(predicate.name)
            symbolic = predicate.formula.eval(assignment)
            { predicate: predicate.name, assignment: assignment.select { |_, v| v }, real: real, symbolic: symbolic } if real != symbolic
          end

          expect(mismatches).to be_empty,
            "#{source.policy_name}##{predicate.name} diverges from real method on #{mismatches.size} input(s); first: #{mismatches.first.inspect}"

          # Completeness: every boolean leaf the REAL method read must appear in
          # the formula. A read not in the formula's vars is a dropped variable —
          # the enumeration above can't see a dimension the formula omits, so this
          # guards the proof against being vacuous. (`member_for.*` reads only
          # happen when the membership is present; the union enumeration exercises
          # those, so any status leaf the method reads gets recorded.)
          dropped = reads - predicate.formula.variables
          expect(dropped).to be_empty,
            "#{source.policy_name}##{predicate.name} reads leaves absent from its formula (dropped variables): #{dropped.to_a.inspect}"
        end
      end
    end
  end
end
