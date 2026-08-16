# typed: true
# frozen_string_literal: true

require_relative "formula"

module PunditSymbolic
  # Resolves same-policy delegation: replaces every `call:other?` marker var with
  # `other?`'s own resolved formula, iterating until only leaf vars remain.
  # Policies delegate in a DAG (capability -> capability -> private role), so this
  # terminates. A method delegating to a refused predicate is refused in turn
  # (recorded, dropped), never crashed on. Kept out of PolicySource so loading and
  # delegation-resolution stay separate concerns.
  class DelegationResolver
    # Sentinel: a method delegates to a predicate that was itself refused.
    class DelegatesToRefused < StandardError
      def initialize(target)
        @target = target
        super
      end

      def target = @target
    end

    # `raw` is name => Formula (with `call:` markers); `defs` is name(Symbol) =>
    # { public: }. `refusals` is the shared array to append delegation refusals
    # to. Returns a list of PolicySource::Predicate.
    def initialize(raw, defs, refusals)
      @raw = raw
      @defs = defs
      @refusals = refusals
      @resolved = {}
    end

    def call
      @raw.each_key do |name|
        resolve(name, [])
      rescue DelegatesToRefused => error
        @refusals << { name: name, public: @defs[name.to_sym][:public], reason: "delegates to refused predicate `#{error.target}`" }
      end
      refused = @refusals.map { |r| r[:name] }.to_set
      @resolved.filter_map do |name, formula|
        next if refused.include?(name) # partial entry from an unwound resolve

        PolicySource::Predicate.new(name: name, formula: formula, public: @defs[name.to_sym][:public])
      end
    end

    private

    def resolve(name, stack)
      return @resolved[name] if @resolved.key?(name)
      raise "delegation cycle through #{name}" if stack.include?(name)

      @resolved[name] = substitute(@raw.fetch(name), stack + [ name ])
    end

    def substitute(node, stack)
      case node
      when Formula::Var
        return node unless node.name.start_with?("call:")

        target = node.name.delete_prefix("call:")
        raise DelegatesToRefused, target unless @raw.key?(target)

        resolve(target, stack)
      when Formula::Not
        Formula::Not.new(substitute(node.operand, stack))
      when Formula::And
        Formula::And.new(substitute(node.left, stack), substitute(node.right, stack))
      when Formula::Or
        Formula::Or.new(substitute(node.left, stack), substitute(node.right, stack))
      else
        node
      end
    end
  end
end
