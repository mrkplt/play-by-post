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
    # as a leaf). `path_helpers` maps non-predicate helper names to their DefNode,
    # so a helper like `def scene = record.scene` inlines into receiver paths
    # (`scene.participant?` -> "record.scene.participant?"). Leaf-fact naming is
    # centralized in #leaf_for.
    def initialize(predicate_names, path_helpers = {})
      @predicate_names = predicate_names.to_set
      @path_helpers = path_helpers
    end

    # Encode a Prism DefNode's body into a Formula. `local_facts` carries locals
    # bound to a fact (the `membership = record.member_for(user)` line) so later
    # `membership&.active?` reads resolve to the right leaf var.
    def encode(def_node)
      @method_name = def_node.name.to_s
      statements = body_statements(def_node)
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

    # True if `def_node` is a pure navigation path helper (single-statement body
    # that is a chain of no-arg reads, possibly T.must-wrapped) — i.e. it can be
    # inlined into a receiver path rather than treated as a predicate.
    def path_helper?(def_node)
      statements = body_statements(def_node)
      return false unless statements.length == 1

      body = statements.first
      return false unless body.is_a?(Prism::CallNode) || t_must?(body)

      receiver_path(body)
      true
    rescue Unencodable
      false
    end

    private

    def body_statements(def_node)
      body = def_node.body
      raise unencodable("empty body") if body.nil?

      body.is_a?(Prism::StatementsNode) ? body.body : [ body ]
    end

    # A setup statement is either a membership binding (mutates local_facts,
    # returns nil) or a `return false unless COND` guard (returns COND as a
    # formula to AND onto the result). Anything else is unencodable.
    def setup_statement(node, local_facts)
      return bind_membership(node, local_facts) if node.is_a?(Prism::LocalVariableWriteNode)
      return guard_condition(node, local_facts) if guard_clause?(node)

      kind = node.class.name.split("::").last.sub(/Node$/, "")
      raise unencodable("non-boolean body (returns via #{kind}) — not a boolean predicate")
    end

    # `membership = <path>.member_for(user)` — bind the local to the canonical
    # membership path, so a later `membership&.active?` maps to
    # "<path>.member_for.active?".
    def bind_membership(node, local_facts)
      call = node.value
      unless call.is_a?(Prism::CallNode) && call.name == :member_for
        raise unencodable("non-boolean body (returns via assignment) — not a boolean predicate")
      end

      local_facts[node.name] = "#{receiver_path(call.receiver)}member_for"
      nil
    end

    # `return false unless COND` — a Prism UnlessNode whose body is a single
    # `return false` and with no else. The method continues only when COND is
    # true, so the encoded guard is COND (AND-ed onto the result).
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

    def guard_condition(node, local_facts)
      expression(node.predicate, local_facts)
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

    # Recognize `TargetPolicy.new(user, <expr>).pred?`. Returns a deferred marker
    # var `xpolicy:TargetPolicy#pred?@<rebase>.` (rebase = <expr>'s path with a
    # trailing dot), or nil if `node` isn't that shape. The registry resolves it.
    def cross_policy_delegation(node)
      receiver = node.receiver
      return nil unless receiver.is_a?(Prism::CallNode) && receiver.name == :new

      constant = receiver.receiver
      return nil unless constant.is_a?(Prism::ConstantReadNode)

      args = receiver.arguments&.arguments
      return nil if args.nil? || args.length != 2 # (user, record_expr)

      rebase = receiver_path(args[1]) # e.g. "record.character.game."
      Formula.var("xpolicy:#{constant.name}##{node.name}@#{rebase}")
    end

    # `X == Y` -> leaf var "X==Y" ; `X != Y` -> ¬"X==Y". Operands are a navigation
    # path (`record.user`) or a string literal (`"rss"`).
    def comparison_leaf(node, local_facts)
      argument = node.arguments&.arguments
      raise unencodable("comparison with unexpected arity") if argument.nil? || argument.length != 1

      leaf = "#{operand_name(node.receiver, local_facts)}==#{operand_name(argument.first, local_facts)}"
      var = Formula.var(leaf)
      node.name == :!= ? Formula.negate(var) : var
    end

    # Canonical name for one side of a comparison: a string literal keeps its
    # quoted value; a navigation is its receiver path without the trailing dot.
    def operand_name(node, _local_facts)
      return node.unescaped.inspect if node.is_a?(Prism::StringNode)
      return "user" if node.is_a?(Prism::CallNode) && node.name == :user && node.receiver.nil?

      receiver_path(node).chomp(".")
    end

    def call_expression(node, local_facts)
      # `!x` / `x.!` — unary negation.
      return Formula.negate(expression(node.receiver, local_facts)) if node.name == :! && node.receiver

      # T.must(x) is a Sorbet nil-unwrap: transparent to the value.
      return expression(t_must_argument(node), local_facts) if t_must?(node)

      # A comparison `X == Y` / `X != Y` is boolean-valued but its truth is a
      # free fact about the (user, record) pair (identity or a value match) — the
      # tool cannot reason about *which* user/value, only whether they match. So
      # it is a leaf, named canonically by both operands. `!=` is the negation.
      return comparison_leaf(node, local_facts) if %i[== !=].include?(node.name)

      # A bare call to another predicate in this policy: inline it as a leaf var
      # named after that predicate, so delegation composes. (Faithfulness holds
      # because the predicate's own formula uses the same var name; cross-method
      # questions resolve on shared vars.)
      if node.receiver.nil? && @predicate_names.include?(node.name.to_s)
        return Formula.var("call:#{node.name}")
      end

      # Cross-policy delegation `OtherPolicy.new(user, <expr>).pred?`: emit a
      # deferred marker the registry resolves by inlining OtherPolicy#pred?'s
      # formula with its `record.` leaves rebased onto <expr>'s path.
      cross = cross_policy_delegation(node)
      return cross if cross

      Formula.var(leaf_for(node, local_facts))
    end

    # Canonical leaf-fact variable name for a world-reading call. A leaf is a
    # boolean-returning method call whose truth the tool treats as free: it is
    # named by the RECEIVER PATH plus the method, so the same real read always
    # gets the same var (record.game.game_master? -> "record.game.game_master?").
    # No hand-maintained whitelist — any policy's fact reads name themselves, and
    # the faithfulness spec pins every name against the real method. Argument
    # lists are dropped from the name: a policy passes only `user` / `record.*`
    # as args, which carry no distinguishing information for a per-(user,record)
    # question.
    def leaf_for(node, local_facts)
      # A boolean leaf is a PREDICATE read (`...game_master?`, `user.present?`).
      # A non-predicate call in boolean position — an operator/comparison like
      # `record.user == user`, or a bare value — is not a free boolean of the
      # (user, record) pair (its truth relates two entities), so it is out of the
      # boolean-leaf theory and must be refused, not encoded as a free var.
      unless node.name.to_s.end_with?("?")
        raise unencodable("non-predicate in boolean position: `#{node.name}` (comparisons/operators are out of theory)")
      end

      # membership&.active? where `membership = <path>.member_for(user)` -> a
      # leaf on that membership path, e.g. "record.game.member_for.active?".
      if node.safe_navigation? && (base = membership_base(node.receiver, local_facts))
        return "#{base}.#{node.name}"
      end

      "#{receiver_path(node.receiver)}#{node.name}"
    end

    # The dotted path of a chain of no-arg calls rooted at `record` (or `user`),
    # ending in a trailing dot: `record.game.` , `record.` , `user.`.
    # Raises Unencodable on anything that isn't such a pure read path.
    def receiver_path(receiver)
      return "" if receiver.nil?
      return receiver_path(t_must_argument(receiver)) if t_must?(receiver)

      unless receiver.is_a?(Prism::CallNode) && no_args?(receiver)
        raise unencodable("unrecognized receiver #{unparse(receiver)}")
      end

      # A bare call to a path-helper (`scene`, `game`) inlines that helper's own
      # path in place of the name (`scene.` -> "record.scene.").
      if receiver.receiver.nil? && (helper = @path_helpers[receiver.name])
        return helper_path(receiver.name, helper)
      end

      "#{receiver_path(receiver.receiver)}#{receiver.name}."
    end

    # The navigation path a path-helper's body produces, as a trailing-dot prefix.
    # The body must itself be a pure path (a chain of no-arg reads, possibly
    # T.must-wrapped); anything else means the "helper" is not a path and the
    # calling method is unencodable.
    def helper_path(name, def_node)
      statements = body_statements(def_node)
      raise unencodable("path helper `#{name}` has a multi-statement body") unless statements.length == 1

      body = statements.first
      raise unencodable("path helper `#{name}` is not a pure navigation path") unless body.is_a?(Prism::CallNode) || t_must?(body)

      receiver_path(body)
    end

    # T.must(x) — a Sorbet nil-unwrap CallNode: receiver `T`, name `must`.
    def t_must?(node)
      return false unless node.is_a?(Prism::CallNode) && node.name == :must

      receiver = node.receiver
      receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
    end

    def t_must_argument(node)
      args = node.arguments&.arguments
      raise unencodable("T.must with unexpected arity") unless args&.length == 1

      args.first
    end

    # If `receiver` is a local bound to `<path>.member_for(user)`, return that
    # path's canonical membership base (e.g. "record.game.member_for").
    def membership_base(receiver, local_facts)
      return nil unless receiver.is_a?(Prism::LocalVariableReadNode)

      local_facts[receiver.name]
    end

    def no_args?(call_node)
      call_node.arguments.nil? && call_node.block.nil?
    end

    def unparse(node)
      node.respond_to?(:name) ? node.name.to_s : node.class.name
    end

    def unencodable(reason) = Unencodable.new(@method_name, reason)
  end
end
