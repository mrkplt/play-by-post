# typed: true
# frozen_string_literal: true

require "prism"
require_relative "formula"
require_relative "unencodable"
require_relative "method_body"

module PunditSymbolic
  # Translates one method body's expression tree into a Formula. Holds the
  # per-method `local_facts` (membership bindings) plus the naming / call-shape
  # collaborators, so the recursive walk takes just a node — no threaded
  # (node, local_facts) clump.
  class ExpressionEncoder
    def initialize(naming, call_shapes, predicate_names)
      @naming = naming
      @call_shapes = call_shapes
      @predicate_names = predicate_names
    end

    # Records `name -> membership_path` for a `membership = ...member_for(user)`
    # binding, so later `membership&.active?` resolves against it.
    def bind(name, membership_call)
      local_facts[name] = "#{@naming.receiver_path(membership_call.receiver)}member_for"
    end

    # A Prism expression node -> Formula.
    def expression(node)
      handler = HANDLERS.find { |type, _| node.is_a?(type) }
      handler ? send(handler.last, node) : refuse("unsupported expression node #{short_name(node)}")
    end

    private

    # Node type -> the method that encodes it. A table so #expression is a lookup,
    # not a long dispatch.
    HANDLERS = {
      Prism::TrueNode => :encode_true,
      Prism::FalseNode => :encode_false,
      Prism::AndNode => :encode_and,
      Prism::OrNode => :encode_or,
      Prism::ParenthesesNode => :encode_parens,
      Prism::CallNode => :call
    }.freeze

    def encode_true(_node) = Formula.const(true)
    def encode_false(_node) = Formula.const(false)
    def encode_and(node) = Formula.conj(expression(node.left), expression(node.right))
    def encode_or(node) = Formula.disj(expression(node.left), expression(node.right))
    def encode_parens(node) = expression(MethodBody.single_statement(node.body) || refuse("expected single expression"))

    def local_facts = @local_facts ||= {}

    def call(node)
      name = node.name
      receiver = node.receiver
      special = special_call(node, name, receiver)
      return special if special

      @call_shapes.cross_policy_delegation(receiver, name) || Formula.var(@naming.leaf_for(node, local_facts))
    end

    # The call shapes that short-circuit before a plain leaf read: negation,
    # T.must unwrap, comparison, and same-policy delegation. nil if none apply.
    def special_call(node, name, receiver)
      return Formula.negate(expression(receiver)) if name == :! && receiver
      return expression(@naming.t_must_argument(node)) if @naming.t_must?(node)
      return @call_shapes.comparison_leaf(node) if %i[== !=].include?(name)

      Formula.var("call:#{name}") if receiver.nil? && @predicate_names.include?(name.to_s)
    end

    def short_name(node) = node.class.name.split("::").last

    def refuse(reason) = raise(Unencodable.new(reason))
  end
end
