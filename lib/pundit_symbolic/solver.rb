# typed: true
# frozen_string_literal: true

require "set"

module PunditSymbolic
  # A complete propositional SAT decision procedure by truth-table enumeration.
  #
  # Our formulas mention only a handful of variables (the leaf facts of one
  # policy), so enumerating all 2^n assignments is instant and — being total —
  # is its own proof of correctness: there is no external solver to trust and no
  # heuristic that could miss a model. `models_for` returns EVERY satisfying
  # assignment, so callers get concrete counterexamples, not just SAT/UNSAT.
  module Solver
    module_function

    # All satisfying assignments of `formula`, as an array of
    # { "var" => bool } hashes. Empty array == UNSAT.
    def models_for(formula)
      vars = formula.variables.to_a.sort
      assignments(vars).select { |assignment| formula.eval(assignment) }
    end

    # True iff at least one assignment satisfies the formula.
    def sat?(formula) = models_for(formula).any?

    # The 2^n assignments over `vars` (sorted names -> bool).
    def assignments(vars)
      Enumerator.new do |yielder|
        (0...(1 << vars.length)).each do |bits|
          assignment = {}
          vars.each_with_index { |name, index| assignment[name] = bits.anybits?(1 << index) }
          yielder << assignment
        end
      end
    end
  end
end
