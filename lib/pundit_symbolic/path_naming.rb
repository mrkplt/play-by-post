# typed: true
# frozen_string_literal: true

require "prism"
require_relative "method_body"
require_relative "unencodable"

module PunditSymbolic
  # Turns a Prism navigation node into a canonical leaf-fact NAME — the one place
  # a Ruby world-read becomes a stable symbol. A leaf is named by its receiver
  # PATH plus the method, so the same real read always gets the same var
  # (`record.game.game_master?` -> "record.game.game_master?"). Path helpers
  # (`def scene = record.scene`) inline into the path; `T.must(x)` is transparent.
  #
  # Raises Unencodable (passed in as `refuse`) on anything outside a
  # pure navigation path, so a construct out of theory is refused, never guessed.
  class PathNaming
    def initialize(path_helpers, refuse)
      @path_helpers = path_helpers
      @refuse = refuse # ->(reason) { raise ... }
    end

    # Canonical leaf name for a boolean predicate read. `local_facts` maps a
    # local bound to `<path>.member_for(user)` to that membership path, so a
    # `membership&.active?` read resolves to "<path>.member_for.active?".
    def leaf_for(node, local_facts)
      name = node.name
      @refuse.call("non-predicate in boolean position: `#{name}` (comparisons/operators are out of theory)") unless name.to_s.end_with?("?")

      "#{prefix_for(node, local_facts)}#{name}"
    end

    # The leaf's path prefix: a `membership&.x?` read on a bound membership local
    # resolves to that membership path; otherwise it's the receiver's path.
    def prefix_for(node, local_facts)
      receiver = node.receiver
      base = node.safe_navigation? && membership_base(receiver, local_facts)
      base ? "#{base}." : receiver_path(receiver)
    end

    # One side of a comparison: a string literal keeps its quoted value, bare
    # `user` stays "user", any other navigation is its receiver path (no trailing
    # dot).
    def operand_name(node)
      return node.unescaped.inspect if node.is_a?(Prism::StringNode)
      return "user" if bare_user?(node)

      receiver_path(node).chomp(".")
    end

    # The dotted path of a chain of no-arg calls rooted at `record`/`user`, ending
    # in a trailing dot: `record.game.`, `record.`, `user.`.
    def receiver_path(receiver)
      return "" if receiver.nil?
      return receiver_path(t_must_argument(receiver)) if t_must?(receiver)
      @refuse.call("unrecognized receiver #{unparse(receiver)}") unless receiver.is_a?(Prism::CallNode) && no_args?(receiver)

      call_path(receiver)
    end

    # The path for a no-arg call node: a path helper inlines its own path, else
    # the receiver's path plus this call's name and a trailing dot.
    def call_path(call)
      name = call.name
      inner = call.receiver
      helper = @path_helpers[name] if inner.nil?
      helper ? helper_path(name, helper) : "#{receiver_path(inner)}#{name}."
    end

    # True if `def_node` is a pure navigation path helper (single-statement body
    # that is a chain of no-arg reads, possibly T.must-wrapped) — inlinable into a
    # receiver path rather than treated as a predicate.
    def path_helper?(def_node)
      body = MethodBody.single_statement(def_node.body)
      return false unless body.is_a?(Prism::CallNode) || t_must?(body)

      receiver_path(body) && true
    rescue Unencodable
      false
    end

    def bare_user?(node)
      node.is_a?(Prism::CallNode) && node.name == :user && node.receiver.nil?
    end

    # T.must(x) — a Sorbet nil-unwrap CallNode (receiver `T`, name `must`).
    def t_must?(node)
      return false unless node.is_a?(Prism::CallNode) && node.name == :must

      receiver = node.receiver
      receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
    end

    def t_must_argument(node)
      case node.arguments&.arguments
      in [ argument ] then argument
      else @refuse.call("T.must with unexpected arity")
      end
    end

    private

    # The navigation path a path-helper's body produces, as a trailing-dot prefix.
    def helper_path(name, def_node)
      body = MethodBody.single_statement(def_node.body)
      @refuse.call("path helper `#{name}` is not a pure single-statement navigation path") unless body.is_a?(Prism::CallNode) || t_must?(body)

      receiver_path(body)
    end

    def membership_base(receiver, local_facts)
      return nil unless receiver.is_a?(Prism::LocalVariableReadNode)

      local_facts[receiver.name]
    end

    def no_args?(call_node)
      call_node.arguments.nil? && call_node.block.nil?
    end

    # A short label for a node in a refusal message: its method name if it has
    # one, else its node type.
    def unparse(node)
      node.is_a?(Prism::CallNode) ? node.name.to_s : node.class.name.split("::").last
    end
  end
end
