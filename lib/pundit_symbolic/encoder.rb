# typed: true
# frozen_string_literal: true

require "prism"
require_relative "formula"

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
    # Raised when a method body falls outside the boolean-over-leaf-facts subset.
    class Unencodable < StandardError
      attr_reader :method_name, :reason

      def initialize(method_name, reason)
        @method_name = method_name
        @reason = reason
        super("#{method_name}: #{reason}")
      end
    end

    # `predicate_names` is the set of same-policy predicates that may be inlined
    # by delegation (so `show?`'s body `view?` resolves rather than being treated
    # as a leaf). Leaf-fact naming is centralized in #leaf_for.
    def initialize(predicate_names)
      @predicate_names = predicate_names.to_set
    end

    # Encode a Prism DefNode's body into a Formula. `local_facts` carries locals
    # bound to a fact (the `membership = record.member_for(user)` line) so later
    # `membership&.active?` reads resolve to the right leaf var.
    def encode(def_node)
      @method_name = def_node.name.to_s
      statements = body_statements(def_node)
      local_facts = {}

      # All but the last statement may only be fact-binding assignments; the
      # last statement is the returned boolean expression.
      *setup, result = statements
      setup.each { |node| bind_local(node, local_facts) }
      expression(result, local_facts)
    end

    private

    def body_statements(def_node)
      body = def_node.body
      raise unencodable("empty body") if body.nil?

      body.is_a?(Prism::StatementsNode) ? body.body : [body]
    end

    # Handle `membership = record.member_for(user)` — record that `membership`
    # names the game's membership for the user, so `membership&.active?` later
    # maps to the `member_active` leaf.
    def bind_local(node, local_facts)
      unless node.is_a?(Prism::LocalVariableWriteNode) && member_for_call?(node.value)
        kind = node.class.name.split("::").last.sub(/Node$/, "")
        raise unencodable("non-boolean body (returns via #{kind}) — not a boolean predicate")
      end

      local_facts[node.name] = :membership
    end

    def member_for_call?(node)
      node.is_a?(Prism::CallNode) && node.name == :member_for &&
        receiver_is_record?(node.receiver)
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

      # A bare call to another predicate in this policy: inline it as a leaf var
      # named after that predicate, so delegation composes. (Faithfulness holds
      # because the predicate's own formula uses the same var name; cross-method
      # questions resolve on shared vars.)
      if node.receiver.nil? && @predicate_names.include?(node.name.to_s)
        return Formula.var("call:#{node.name}")
      end

      Formula.var(leaf_for(node, local_facts))
    end

    # Canonical leaf-fact variable name for a world-reading call. This is the
    # ONE place a Ruby fact-read becomes a symbol; the faithfulness spec pins
    # each mapping against the real policy, so this table is the trusted core.
    def leaf_for(node, local_facts)
      # record.game_master?(user) -> gm ; record.viewable_by?(user) -> viewable
      if receiver_is_record?(node.receiver)
        case node.name
        when :game_master? then return "gm"
        when :viewable_by? then return "viewable"
        end
      end

      # membership&.game_master? / membership&.active? -> member_gm / member_active
      if node.safe_navigation? && membership_local?(node.receiver, local_facts)
        case node.name
        when :game_master? then return "member_gm"
        when :active? then return "member_active"
        when :removed? then return "member_removed"
        end
      end

      raise unencodable("unrecognized fact read: #{unparse(node)}")
    end

    def receiver_is_record?(receiver)
      receiver.is_a?(Prism::CallNode) && receiver.name == :record && receiver.receiver.nil?
    end

    def membership_local?(receiver, local_facts)
      receiver.is_a?(Prism::LocalVariableReadNode) && local_facts[receiver.name] == :membership
    end

    def unparse(node)
      node.respond_to?(:name) ? node.name.to_s : node.class.name
    end

    def unencodable(reason) = Unencodable.new(@method_name, reason)
  end
end
