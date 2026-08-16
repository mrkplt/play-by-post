# typed: true
# frozen_string_literal: true

require "prism"
require_relative "formula"
require_relative "unencodable"
require_relative "path_naming"
require_relative "method_body"
require_relative "call_shapes"

module PunditSymbolic
  # Translates a single Pundit policy method body (real Ruby source, parsed with
  # Prism) into a propositional Formula over leaf facts.
  #
  # Scope is deliberately our Pundit pattern and nothing wider. The encodable
  # subset is exactly what a boolean capability predicate is built from:
  #
  #   * `true` / `false` literals            -> Const
  #   * `&&`/`and`, `||`/`or`, `!`/`not`     -> And / Or / Not
  #   * a call to another predicate in the   -> inlined (delegation:
  #     same policy (`view?`, `manage?`)        `show? => view?`)
  #   * a call that reads a fact about the    -> a free variable (leaf fact),
  #     world (`record.game_master?(user)`,     named canonically
  #     `member_for(user)&.active?`)
  #   * the `membership = record.member_for(user); (membership&.x || ...) || false`
  #     shape used by write_access?          -> the safe-nav chains become
  #                                             member_<x> leaf vars
  #
  # ANYTHING ELSE raises Unencodable. A public predicate that cannot be encoded
  # is a finding, not a silent skip: either the encoder is incomplete or the
  # policy violates the "public surface is boolean predicates" convention.
  class Encoder
    # `predicate_names` is the set of same-policy predicates that may be inlined
    # by delegation (so `show?`'s body `view?` resolves rather than being treated
    # as a leaf). `path_helpers` maps non-predicate helper names to their DefNode,
    # so a helper like `def scene = record.scene` inlines into receiver paths
    # (`scene.participant?` -> "record.scene.participant?"). Leaf-fact naming is
    # centralized in #leaf_for.
    def initialize(predicate_names, path_helpers = {})
      @predicate_names = predicate_names.to_set
      @path_helpers = path_helpers
      refuse = ->(reason) { raise unencodable(reason) }
      @naming = PathNaming.new(path_helpers, refuse)
      @call_shapes = CallShapes.new(@naming, refuse)
    end

    # Encode a Prism DefNode's body into a Formula. `local_facts` carries locals
    # bound to a fact (the `membership = record.member_for(user)` line) so later
    # `membership&.active?` reads resolve to the right leaf var.
    def encode(def_node)
      statements = MethodBody.statements(def_node) || raise(unencodable("empty body"))
      local_facts = {}

      # All but the last statement are setup: either a fact-binding assignment
      # (`membership = record.member_for(user)`) or a `return false unless COND`
      # guard, which contributes `COND &&` to the result. The last statement is
      # the returned boolean expression.
      *setup, result = statements
      guards = setup.filter_map { |node| setup_statement(node, local_facts) }
      formula = expression(result, local_facts)
      guards.reduce(formula) { |acc, guard| Formula.conj(guard, acc) }
    end

    # True if `def_node` is a pure navigation path helper (see PathNaming).
    def path_helper?(def_node) = @naming.path_helper?(def_node)

    private

    # A setup statement is a membership binding (records the local, returns nil)
    # or a `return false unless COND` guard (returns COND to AND onto the result).
    def setup_statement(node, local_facts)
      if (call = MethodBody.membership_binding(node))
        local_facts[node.name] = "#{@naming.receiver_path(call.receiver)}member_for"
        return nil
      end
      return expression(node.predicate, local_facts) if MethodBody.guard_clause?(node)

      kind = node.class.name.split("::").last.sub(/Node$/, "")
      raise unencodable("non-boolean body (returns via #{kind}) — not a boolean predicate")
    end

    # The core translation: a Prism expression node -> Formula.
    def expression(node, local_facts)
      case node
      when Prism::TrueNode then Formula.const(true)
      when Prism::FalseNode then Formula.const(false)
      when Prism::AndNode
        Formula.conj(expression(node.left, local_facts), expression(node.right, local_facts))
      when Prism::OrNode
        Formula.disj(expression(node.left, local_facts), expression(node.right, local_facts))
      when Prism::ParenthesesNode
        expression(single_child(node.body), local_facts)
      when Prism::CallNode
        call_expression(node, local_facts)
      else
        raise unencodable("unsupported expression node #{node.class.name.split('::').last}")
      end
    end

    def single_child(statements)
      raise unencodable("expected single expression") unless statements.is_a?(Prism::StatementsNode) && statements.body.length == 1

      statements.body.first
    end

    def call_expression(node, local_facts)
      # `!x` / `x.!` — unary negation.
      return Formula.negate(expression(node.receiver, local_facts)) if node.name == :! && node.receiver

      # T.must(x) is a Sorbet nil-unwrap: transparent to the value.
      return expression(@naming.t_must_argument(node), local_facts) if @naming.t_must?(node)

      # A comparison is a leaf named by its operands (CallShapes).
      return @call_shapes.comparison_leaf(node) if %i[== !=].include?(node.name)

      # A bare call to another predicate in this policy: inline it as a `call:`
      # marker so delegation composes on shared vars (resolved in PolicySource).
      if node.receiver.nil? && @predicate_names.include?(node.name.to_s)
        return Formula.var("call:#{node.name}")
      end

      # Cross-policy delegation -> a deferred xpolicy marker (CallShapes), or a
      # plain leaf read named by its path.
      @call_shapes.cross_policy_delegation(node) || Formula.var(@naming.leaf_for(node, local_facts))
    end

    def unencodable(reason) = Unencodable.new(reason)
  end
end
