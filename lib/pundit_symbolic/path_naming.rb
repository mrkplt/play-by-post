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
      unless node.name.to_s.end_with?("?")
        @refuse.call("non-predicate in boolean position: `#{node.name}` (comparisons/operators are out of theory)")
      end

      if node.safe_navigation? && (base = membership_base(node.receiver, local_facts))
        return "#{base}.#{node.name}"
      end

      "#{receiver_path(node.receiver)}#{node.name}"
    end

    # One side of a comparison: a string literal keeps its quoted value, bare
    # `user` stays "user", any other navigation is its receiver path (no trailing
    # dot).
    def operand_name(node)
      return node.unescaped.inspect if node.is_a?(Prism::StringNode)
      return "user" if node.is_a?(Prism::CallNode) && node.name == :user && node.receiver.nil?

      receiver_path(node).chomp(".")
    end

    # The dotted path of a chain of no-arg calls rooted at `record`/`user`, ending
    # in a trailing dot: `record.game.`, `record.`, `user.`.
    def receiver_path(receiver)
      return "" if receiver.nil?
      return receiver_path(t_must_argument(receiver)) if t_must?(receiver)

      unless receiver.is_a?(Prism::CallNode) && no_args?(receiver)
        @refuse.call("unrecognized receiver #{unparse(receiver)}")
      end

      if receiver.receiver.nil? && (helper = @path_helpers[receiver.name])
        return helper_path(receiver.name, helper)
      end

      "#{receiver_path(receiver.receiver)}#{receiver.name}."
    end

    # True if `def_node` is a pure navigation path helper (single-statement body
    # that is a chain of no-arg reads, possibly T.must-wrapped) — inlinable into a
    # receiver path rather than treated as a predicate.
    def path_helper?(def_node)
      statements = MethodBody.statements(def_node)
      return false unless statements&.length == 1

      body = statements.first
      return false unless body.is_a?(Prism::CallNode) || t_must?(body)

      receiver_path(body)
      true
    rescue Unencodable
      false
    end

    # T.must(x) — a Sorbet nil-unwrap CallNode (receiver `T`, name `must`).
    def t_must?(node)
      return false unless node.is_a?(Prism::CallNode) && node.name == :must

      receiver = node.receiver
      receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
    end

    def t_must_argument(node)
      args = node.arguments&.arguments
      @refuse.call("T.must with unexpected arity") if args.nil? || args.length != 1

      args.first
    end

    private

    # The navigation path a path-helper's body produces, as a trailing-dot prefix.
    def helper_path(name, def_node)
      body = def_node.body
      statements = body.is_a?(Prism::StatementsNode) ? body.body : [ body ]
      @refuse.call("path helper `#{name}` has a multi-statement body") unless statements.length == 1

      first = statements.first
      @refuse.call("path helper `#{name}` is not a pure navigation path") unless first.is_a?(Prism::CallNode) || t_must?(first)

      receiver_path(first)
    end

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
  end
end
