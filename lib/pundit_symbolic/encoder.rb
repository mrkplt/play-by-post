# typed: true
# frozen_string_literal: true

require "prism"
require_relative "formula"
require_relative "unencodable"
require_relative "path_naming"
require_relative "method_body"
require_relative "call_shapes"
require_relative "expression_encoder"

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
      *setup, result = MethodBody.statements(def_node) || raise(unencodable("empty body"))
      walk = ExpressionEncoder.new(@naming, @call_shapes, @predicate_names)
      # Each setup statement is a membership binding or a `return false unless
      # COND` guard; guards AND onto the result (the last statement's expression).
      guarded(setup.filter_map { |node| setup_statement(node, walk) }, walk.expression(result))
    end

    def guarded(guards, result)
      guards.reduce(result) { |acc, guard| Formula.conj(guard, acc) }
    end

    # True if `def_node` is a pure navigation path helper (see PathNaming).
    def path_helper?(def_node) = @naming.path_helper?(def_node)

    private

    # A setup statement is a membership binding (records the local, returns nil)
    # or a `return false unless COND` guard (returns COND to AND onto the result).
    def setup_statement(node, walk)
      binding = MethodBody.membership_binding(node)
      return walk.bind(node.name, binding) && nil if binding
      return walk.expression(node.predicate) if MethodBody.guard_clause?(node)

      raise unencodable("non-boolean body (returns via #{node_kind(node)}) — not a boolean predicate")
    end

    def node_kind(node) = node.class.name.split("::").last.sub(/Node$/, "")

    def unencodable(reason) = Unencodable.new(reason)
  end
end
