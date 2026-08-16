# typed: true
# frozen_string_literal: true

require "prism"
require_relative "encoder"

module PunditSymbolic
  # Loads one policy's source, encodes each method, and resolves delegation so
  # every public predicate is a formula over LEAF facts only (no `call:` vars
  # left). This is what lets cross-method questions compare `show?` and `view?`
  # on shared leaf variables.
  class PolicySource
    Predicate = Struct.new(:name, :formula, :public, keyword_init: true) do
      def public? = public
    end

    attr_reader :policy_name, :predicates, :refusals

    def self.load(path)
      new(path).tap(&:build)
    end

    def initialize(path)
      @path = path
      @refusals = []
    end

    def build
      program = Prism.parse_file(@path).value
      class_node = find_policy_class(program)
      @policy_name = class_node.name.to_s
      defs = method_defs(class_node)

      encoder = Encoder.new(defs.keys.map(&:to_s))
      raw = encode_all(defs, encoder)
      @predicates = resolve_delegations(raw, defs)
      self
    end

    # Public predicates only (the authorization surface). Refused methods are in
    # #refusals, keyed by name with a reason.
    def public_predicates
      @predicates.select(&:public?)
    end

    private

    def find_policy_class(program)
      program.statements.body.grep(Prism::ClassNode).first ||
        raise("no class definition in #{@path}")
    end

    # name(Symbol) -> { node:, public: } for every instance method def.
    def method_defs(class_node)
      visibility = :public
      defs = {}
      class_node.body.body.each do |node|
        visibility = :private if private_marker?(node)
        defs[node.name] = { node: node, public: visibility == :public } if node.is_a?(Prism::DefNode)
      end
      defs
    end

    def private_marker?(node)
      node.is_a?(Prism::CallNode) && node.name == :private && node.arguments.nil?
    end

    def encode_all(defs, encoder)
      raw = {}
      defs.each do |name, info|
        raw[name.to_s] = encoder.encode(info[:node])
      rescue Encoder::Unencodable => error
        @refusals << { name: name.to_s, public: info[:public], reason: error.reason }
      end
      raw
    end

    # Replace every `call:other?` var with `other?`'s own (already-resolved)
    # formula, iterating until only leaf vars remain. Policies here delegate in a
    # DAG (capability -> capability -> private role), so this terminates.
    def resolve_delegations(raw, defs)
      resolved = {}
      raw.each_key { |name| resolve(name, raw, resolved, []) }
      resolved.map do |name, formula|
        Predicate.new(name: name, formula: formula, public: defs[name.to_sym][:public])
      end
    end

    def resolve(name, raw, resolved, stack)
      return resolved[name] if resolved.key?(name)
      raise "delegation cycle through #{name}" if stack.include?(name)

      resolved[name] = substitute(raw.fetch(name), raw, resolved, stack + [name])
    end

    def substitute(node, raw, resolved, stack)
      case node
      when Formula::Var
        target = node.name.delete_prefix("call:")
        node.name.start_with?("call:") ? resolve(target, raw, resolved, stack) : node
      when Formula::Not
        Formula::Not.new(substitute(node.operand, raw, resolved, stack))
      when Formula::And
        Formula::And.new(substitute(node.left, raw, resolved, stack), substitute(node.right, raw, resolved, stack))
      when Formula::Or
        Formula::Or.new(substitute(node.left, raw, resolved, stack), substitute(node.right, raw, resolved, stack))
      else
        node
      end
    end
  end
end
