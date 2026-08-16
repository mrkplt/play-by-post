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
    # `receiver` is the delegation's receiver node, `predicate` the called name.
    def cross_policy_delegation(receiver, predicate)
      PolicyConstruction.of(receiver)&.marker(@naming, predicate)
    end

    # `X == Y` -> leaf "X==Y" ; `X != Y` -> ¬"X==Y". A comparison is boolean but
    # its truth is a free fact about the (user, record) pair (the tool can't
    # reason about which value), so it's a leaf named by both operands.
    def comparison_leaf(node)
      negate = node.name == :!=
      leaf = "#{@naming.operand_name(node.receiver)}==#{@naming.operand_name(single_argument(node))}"
      var = Formula.var(leaf)
      negate ? Formula.negate(var) : var
    end

    private

    def single_argument(node)
      case node.arguments&.arguments
      in [ argument ] then argument
      else @refuse.call("comparison with unexpected arity")
      end
    end

    # Matches `SomePolicy.new(user, <record_expr>)`; owns the policy constant name
    # and record argument, and builds the deferred marker var, keeping that
    # receiver-shape logic off CallShapes.
    class PolicyConstruction
      def self.of(node)
        return nil unless node.is_a?(Prism::CallNode) && node.name == :new

        constant = node.receiver
        return nil unless constant.is_a?(Prism::ConstantReadNode)

        case node.arguments&.arguments
        in [ _user, record_arg ] then new(constant.name, record_arg)
        else nil
        end
      end

      def initialize(policy, record_arg)
        @policy = policy
        @record_arg = record_arg
      end

      # `xpolicy:Policy#predicate@<rebase>.` — the deferred marker the registry
      # resolves by rebasing the target predicate's formula onto this record path.
      def marker(naming, predicate)
        Formula.var("xpolicy:#{@policy}##{predicate}@#{naming.receiver_path(@record_arg)}")
      end
    end
  end
end
