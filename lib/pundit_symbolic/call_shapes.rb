# typed: true
# frozen_string_literal: true

require "prism"
require_relative "formula"

module PunditSymbolic
  # The two special CallNode shapes that translate to a leaf without recursing
  # into subexpressions: a cross-policy delegation marker, and a comparison. Kept
  # out of Encoder so its recursive `expression`/`call_expression` walk stays the
  # single concern there. `naming` supplies canonical path names; `refuse` raises.
  class CallShapes
    def initialize(naming, refuse)
      @naming = naming
      @refuse = refuse
    end

    # `TargetPolicy.new(user, <expr>).pred?` -> a deferred marker var
    # `xpolicy:TargetPolicy#pred?@<rebase>.` the registry resolves by inlining the
    # target predicate's formula rebased onto <expr>'s path. nil if not that shape.
    def cross_policy_delegation(node)
      receiver = node.receiver
      return nil unless receiver.is_a?(Prism::CallNode) && receiver.name == :new

      constant = receiver.receiver
      return nil unless constant.is_a?(Prism::ConstantReadNode)

      args = receiver.arguments&.arguments
      return nil if args.nil? || args.length != 2 # (user, record_expr)

      rebase = @naming.receiver_path(args[1]) # e.g. "record.character.game."
      Formula.var("xpolicy:#{constant.name}##{node.name}@#{rebase}")
    end

    # `X == Y` -> leaf "X==Y" ; `X != Y` -> ¬"X==Y". A comparison is boolean but
    # its truth is a free fact about the (user, record) pair (the tool can't
    # reason about which value), so it's a leaf named by both operands.
    def comparison_leaf(node)
      argument = node.arguments&.arguments
      @refuse.call("comparison with unexpected arity") if argument.nil? || argument.length != 1

      leaf = "#{@naming.operand_name(node.receiver)}==#{@naming.operand_name(argument.first)}"
      var = Formula.var(leaf)
      node.name == :!= ? Formula.negate(var) : var
    end
  end
end
