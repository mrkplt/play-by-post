# typed: true
# frozen_string_literal: true

require_relative "policy_source"
require_relative "formula"

module PunditSymbolic
  # Loads every policy and resolves CROSS-policy delegation — a predicate whose
  # body is `OtherPolicy.new(user, <expr>).pred?`. A single PolicySource can only
  # see its own file, so those references are left as deferred `xpolicy:` marker
  # vars; the registry rewrites each by inlining the target predicate's resolved
  # formula with its `record.` leaves rebased onto <expr>'s path.
  #
  #   CharacterVersionPolicy#show? = GamePolicy.new(user, record.character.game).view?
  #     -> GamePolicy#view? is `record.viewable_by?`
  #     -> rebased: `record.character.game.viewable_by?`
  class PolicyRegistry
    XPOLICY = /\Axpolicy:(?<target>\w+)#(?<pred>[\w?]+)@(?<rebase>.*)\z/

    attr_reader :sources

    def self.load_dir(dir)
      paths = Dir[File.join(dir, "*_policy.rb")].reject { |path| path.end_with?("application_policy.rb") }
      new(paths.sort.map { |path| PolicySource.load(path) })
    end

    def initialize(sources)
      @sources = sources
      @by_policy = sources.to_h { |source| [ source.policy_name, source ] }
      resolve_cross_policy!
    end

    private

    # Rewrite every predicate's formula, replacing xpolicy markers with the
    # target predicate's formula rebased onto the delegation path. A marker whose
    # target predicate is missing (refused, or not a public predicate) makes the
    # referring predicate unresolvable — recorded as a refusal, dropped from the
    # source's predicate list.
    def resolve_cross_policy!
      sources.each { |source| source.predicates.replace(resolved_predicates(source)) }
    end

    UNRESOLVABLE_REASON = "delegates to an unresolvable cross-policy predicate"

    def resolved_predicates(source)
      source.predicates.filter_map do |predicate|
        rewritten = rewrite(predicate.formula)
        rewritten ? predicate.with_formula(rewritten) : refuse(predicate, source)
      end
    end

    def refuse(predicate, source)
      source.refusals << predicate.refusal(UNRESOLVABLE_REASON)
      nil
    end

    # Sentinel unwinding a formula whose xpolicy marker can't be resolved.
    Unresolvable = Class.new(StandardError)

    # Returns the formula with xpolicy markers resolved, or nil if any marker
    # can't be resolved.
    def rewrite(node)
      Formula.map_vars(node) { |var| resolve_var(var) }
    rescue Unresolvable
      nil
    end

    # A parsed xpolicy marker. Finds its own target predicate given the policy
    # index, keeping that field access off the registry (no FeatureEnvy).
    Marker = Struct.new(:target, :pred, :rebase) do
      def self.parse(name)
        match = XPOLICY.match(name)
        match && new(match[:target], match[:pred], match[:rebase])
      end

      def predicate_in(by_policy)
        by_policy[target]&.predicates&.find { |candidate| candidate.name == pred }
      end
    end

    def resolve_var(var)
      marker = Marker.parse(var.name)
      return var unless marker

      resolve_marker(marker) || raise(Unresolvable)
    end

    def resolve_marker(marker)
      predicate = marker.predicate_in(@by_policy)
      # The target's formula is already leaf-only; rebase its record.-rooted
      # leaves onto the delegation path (e.g. "record." -> "record.character.game.").
      predicate && rebased(predicate.formula, marker.rebase)
    end

    def rebased(formula, rebase)
      Formula.map_vars(formula) { |var| Formula.var(var.name.sub(/\Arecord\./, rebase)) }
    end
  end
end
