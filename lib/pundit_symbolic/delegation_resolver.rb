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
      @raw.each_key { |name| resolve_top(name) }
      surviving_predicates
    end

    private

    def surviving_predicates
      refused = @refusals.map { |refusal| refusal[:name] }.to_set
      @resolved.filter_map do |name, formula|
        predicate(name, formula) unless refused.include?(name) # unwound partial
      end
    end

    def resolve_top(name)
      resolve(name, [])
    rescue DelegatesToRefused => error
      @refusals << { name: name, public: public?(name), reason: "delegates to refused predicate `#{error.target}`" }
    end

    def predicate(name, formula)
      PolicySource::Predicate.new(name: name, formula: formula, public: public?(name))
    end

    def public?(name) = @defs[name.to_sym][:public]

    def resolve(name, stack)
      return @resolved[name] if @resolved.key?(name)
      raise "delegation cycle through #{name}" if stack.include?(name)

      @resolved[name] = Formula.map_vars(@raw.fetch(name)) { |var| substitute_var(var, stack + [ name ]) }
    end

    # A `call:other?` marker resolves to other?'s formula (refused-in-turn if the
    # target was refused); any other var passes through unchanged.
    def substitute_var(var, stack)
      name = var.name
      return var unless name.start_with?("call:")

      target = name.delete_prefix("call:")
      raise DelegatesToRefused, target unless @raw.key?(target)

      resolve(target, stack)
    end
  end
end
