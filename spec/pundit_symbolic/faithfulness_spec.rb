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
# Runs without booting Rails: GamePolicy is a pure (user, record) object, so we
# stand up doubles that answer exactly the leaf reads the policy makes.
RSpec.describe "PunditSymbolic encoder faithfulness", type: :model do
  # A membership stand-in: answers the status/role predicates the policy asks.
  Membership = Struct.new(:game_master, :active, :removed) do
    def game_master? = game_master
    def active? = active
    def removed? = removed
  end

  # A game stand-in: routes the policy's leaf reads to the assignment. Only the
  # methods GamePolicy actually calls are implemented; anything else is a bug in
  # the encoder's leaf map and should blow up loudly here.
  class GameDouble
    def initialize(assignment)
      @assignment = assignment
    end

    def game_master?(_user) = @assignment.fetch("gm")
    def viewable_by?(_user) = @assignment.fetch("viewable")

    def member_for(_user)
      return nil unless membership?

      Membership.new(
        @assignment.fetch("member_gm", false),
        @assignment.fetch("member_active", false),
        @assignment.fetch("member_removed", false)
      )
    end

    private

    # A nil membership is the assignment where all member_* leaves are false —
    # exactly what the safe-nav (`membership&.x`) collapses to in the real code.
    def membership?
      %w[member_gm member_active member_removed].any? { |leaf| @assignment.fetch(leaf, false) }
    end
  end

  let(:policy_path) { File.expand_path("../../app/policies/game_policy.rb", __dir__) }
  let(:source) { PunditSymbolic::PolicySource.load(policy_path) }

  it "encodes only boolean predicates and refuses the rest, matching the real class" do
    real_publics = GamePolicy.instance_methods(false).map(&:to_s)
    encoded = source.public_predicates.map(&:name)
    refused = source.refusals.map { |r| r[:name] }

    # Every public method is accounted for: either encoded or explicitly refused.
    expect((encoded + refused).sort).to include(*real_publics.sort)
    # export_scene_selection is the non-boolean public method; it must be refused.
    expect(refused).to include("export_scene_selection")
  end

  # THE PROOF: exhaustive differential equivalence, per encodable predicate.
  it "produces a formula that agrees with the real method on EVERY input" do
    source.public_predicates.each do |predicate|
      vars = predicate.formula.variables.to_a
      mismatches = PunditSymbolic::Solver.assignments(vars).filter_map do |assignment|
        real = GamePolicy.new(:user_double, GameDouble.new(assignment)).public_send(predicate.name)
        symbolic = predicate.formula.eval(assignment)
        { predicate: predicate.name, assignment: assignment, real: real, symbolic: symbolic } if real != symbolic
      end

      expect(mismatches).to be_empty,
        "#{predicate.name} formula diverges from real method: #{mismatches.inspect}"
    end
  end
end
