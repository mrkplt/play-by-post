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

    # The 2^n assignments over `vars` (sorted names -> bool). Eager: n is single
    # digits, and callers treat the result as an array.
    def assignments(vars)
      (0...(1 << vars.length)).map { |bits| assignment_for(vars, bits) }
    end

    # One assignment: bit `i` of `bits` gives the value of `vars[i]`.
    def assignment_for(vars, bits)
      vars.each_with_index.to_h { |name, index| [ name, bits.anybits?(1 << index) ] }
    end
  end
end
