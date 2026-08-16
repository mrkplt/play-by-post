# typed: true
# frozen_string_literal: true

module PunditSymbolic
  # A propositional formula over named leaf facts (free boolean variables).
  #
  # This is the whole theory the tool needs: our Pundit predicates are boolean
  # expressions over a handful of opaque leaf facts (`gm`, `viewable`,
  # `member_active`, ...). No arithmetic, no arrays — so a formula is just an
  # AND/OR/NOT/VAR/CONST tree, and SAT is decided by truth-table enumeration
  # over the finite set of variables it mentions (see Solver).
  module Formula
    # Every node answers #eval(assignment) -> bool and #variables -> Set<String>.
    Var = Struct.new(:name) do
      def eval(assignment) = assignment.fetch(name)
      def variables = Set[name]
      def to_s = name
    end

    Const = Struct.new(:value) do
      def eval(_assignment) = value
      def variables = Set.new
      def to_s = value.to_s
    end

    Not = Struct.new(:operand) do
      def eval(assignment) = !operand.eval(assignment)
      def variables = operand.variables
      def to_s = "¬#{operand}"
    end

    And = Struct.new(:left, :right) do
      def eval(assignment) = left.eval(assignment) && right.eval(assignment)
      def variables = left.variables | right.variables
      def to_s = "(#{left} ∧ #{right})"
    end

    Or = Struct.new(:left, :right) do
      def eval(assignment) = left.eval(assignment) || right.eval(assignment)
      def variables = left.variables | right.variables
      def to_s = "(#{left} ∨ #{right})"
    end

    module_function

    def var(name) = Var.new(name.to_s)
    def const(value) = Const.new(value)
    def negate(node) = Not.new(node)
    def conj(left, right) = And.new(left, right)
    def disj(left, right) = Or.new(left, right)
  end
end
