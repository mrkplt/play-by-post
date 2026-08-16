# typed: true
# frozen_string_literal: true

require "prism"

module PunditSymbolic
  # Stateless structural recognizers over a Prism method body — the "what shape
  # is this node" questions the encoder asks while walking a policy method. Kept
  # separate from the translation (Encoder) so each stays a single concern.
  module MethodBody
    module_function

    # The body's statements as an array (a lone expression body is wrapped).
    # Returns nil for an empty body (the caller decides how to refuse).
    def statements(def_node)
      body = def_node.body
      return nil if body.nil?

      body.is_a?(Prism::StatementsNode) ? body.body : [ body ]
    end

    # The single statement inside a StatementsNode, or nil if it isn't exactly one
    # (e.g. a parenthesized expression's contents).
    def single_statement(nodes)
      contents = nodes.is_a?(Prism::StatementsNode) ? nodes.body : []
      contents.first if contents.one?
    end

    # `return false unless COND` — an UnlessNode whose only body statement is
    # `return false`, no else. (The caller reads node.predicate for COND.)
    def guard_clause?(node)
      return false unless node.is_a?(Prism::UnlessNode) && node.else_clause.nil?

      body = node.statements&.body
      return false if body.nil? || body.length != 1

      returns_false?(body.first)
    end

    def returns_false?(node)
      return false unless node.is_a?(Prism::ReturnNode)

      args = node.arguments&.arguments
      return false if args.nil? || args.length != 1

      args.first.is_a?(Prism::FalseNode)
    end

    # `membership = <path>.member_for(user)` — a local bound to a membership
    # lookup. Returns the assignment's CallNode, or nil.
    def membership_binding(node)
      return nil unless node.is_a?(Prism::LocalVariableWriteNode)

      call = node.value
      call.is_a?(Prism::CallNode) && call.name == :member_for ? call : nil
    end
  end
end
