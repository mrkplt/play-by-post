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

      encoder = Encoder.new(defs.keys.map(&:to_s), path_helpers(defs))
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

    # Pundit's field-level authorization methods return an attribute list, not a
    # boolean. They are authorization but a different surface; the tool neither
    # encodes nor flags them.
    FIELD_AUTHZ_METHODS = %i[
      permitted_attributes permitted_attributes_for_create permitted_attributes_for_update
    ].freeze

    # name(Symbol) -> { node:, public: } for every instance method def, minus the
    # field-authz methods (a different, expected non-predicate surface).
    def method_defs(class_node)
      visibility = :public
      defs = {}
      class_node.body.body.each do |node|
        visibility = :private if private_marker?(node)
        next unless node.is_a?(Prism::DefNode) && !FIELD_AUTHZ_METHODS.include?(node.name)

        defs[node.name] = { node: node, public: visibility == :public }
      end
      defs
    end

    def private_marker?(node)
      node.is_a?(Prism::CallNode) && node.name == :private && node.arguments.nil?
    end

    # Non-predicate helper methods whose body is a pure navigation path, e.g.
    #   def scene = record.scene          -> "scene" resolves to path "record.scene"
    #   def game  = T.must(scene.game)     -> "game"  resolves to "record.scene.game"
    # The encoder inlines these into receiver paths so a call like
    # `scene.participant?` becomes the leaf "record.scene.participant?". Only
    # methods NOT ending in `?` are candidates (predicates are boolean, not paths);
    # the encoder validates the body is actually a pure path when it inlines.
    def path_helpers(defs)
      defs.reject { |name, _| name.to_s.end_with?("?") }
          .transform_values { |info| info[:node] }
    end

    def encode_all(defs, encoder)
      raw = {}
      defs.each do |name, info|
        # Path helpers (non-predicate navigation methods like `def scene =
        # record.scene`) exist only to be inlined into predicates; they are not
        # part of the authorization surface, so they are neither encoded as
        # predicates nor reported as refusals.
        next if !name.to_s.end_with?("?") && encoder.path_helper?(info[:node])

        raw[name.to_s] = encoder.encode(info[:node])
      rescue Encoder::Unencodable => error
        @refusals << { name: name.to_s, public: info[:public], reason: error.reason }
      end
      raw
    end

    # Sentinel: a method delegates to a predicate that was itself refused, so it
    # cannot be resolved to leaf facts and must be refused in turn.
    class DelegatesToRefused < StandardError
      attr_reader :target

      def initialize(target)
        @target = target
        super
      end
    end

    # Replace every `call:other?` var with `other?`'s own (already-resolved)
    # formula, iterating until only leaf vars remain. Policies here delegate in a
    # DAG (capability -> capability -> private role), so this terminates. A method
    # delegating to a refused predicate is refused in turn, not crashed on.
    def resolve_delegations(raw, defs)
      resolved = {}
      raw.each_key do |name|
        resolve(name, raw, resolved, [])
      rescue DelegatesToRefused => error
        @refusals << { name: name, public: defs[name.to_sym][:public], reason: "delegates to refused predicate `#{error.target}`" }
      end
      refused_names = @refusals.map { |refusal| refusal[:name] }.to_set
      resolved.filter_map do |name, formula|
        next if refused_names.include?(name) # partial entry from an unwound resolve

        Predicate.new(name: name, formula: formula, public: defs[name.to_sym][:public])
      end
    end

    def resolve(name, raw, resolved, stack)
      return resolved[name] if resolved.key?(name)
      raise "delegation cycle through #{name}" if stack.include?(name)

      resolved[name] = substitute(raw.fetch(name), raw, resolved, stack + [ name ])
    end

    def substitute(node, raw, resolved, stack)
      case node
      when Formula::Var
        return node unless node.name.start_with?("call:")

        target = node.name.delete_prefix("call:")
        raise DelegatesToRefused, target unless raw.key?(target)

        resolve(target, raw, resolved, stack)
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
