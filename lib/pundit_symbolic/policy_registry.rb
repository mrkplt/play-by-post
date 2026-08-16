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
      paths = Dir[File.join(dir, "*_policy.rb")].reject { |p| p.end_with?("application_policy.rb") }
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
      sources.each do |source|
        kept = source.predicates.filter_map do |predicate|
          rewritten = rewrite(predicate.formula)
          if rewritten
            PolicySource::Predicate.new(name: predicate.name, formula: rewritten, public: predicate.public?)
          else
            source.refusals << { name: predicate.name, public: predicate.public?, reason: "delegates to an unresolvable cross-policy predicate" }
            nil
          end
        end
        source.predicates.replace(kept)
      end
    end

    # Returns the formula with xpolicy markers resolved, or nil if any marker
    # can't be resolved.
    def rewrite(node)
      case node
      when Formula::Var
        match = XPOLICY.match(node.name)
        return node unless match

        resolve_marker(match)
      when Formula::Not
        inner = rewrite(node.operand)
        inner && Formula::Not.new(inner)
      when Formula::And
        left = rewrite(node.left)
        right = rewrite(node.right)
        left && right && Formula::And.new(left, right)
      when Formula::Or
        left = rewrite(node.left)
        right = rewrite(node.right)
        left && right && Formula::Or.new(left, right)
      else
        node
      end
    end

    def resolve_marker(match)
      target = @by_policy[match[:target]]
      return nil unless target

      predicate = target.predicates.find { |p| p.name == match[:pred] }
      return nil unless predicate

      # The target's formula is already leaf-only; rebase its record.-rooted
      # leaves onto the delegation path (e.g. "record." -> "record.character.game.").
      rebase_leaves(predicate.formula, match[:rebase])
    end

    # Replace the leading "record." of every leaf var with `rebase`.
    def rebase_leaves(node, rebase)
      case node
      when Formula::Var
        Formula::Var.new(node.name.sub(/\Arecord\./, rebase))
      when Formula::Not
        Formula::Not.new(rebase_leaves(node.operand, rebase))
      when Formula::And
        Formula::And.new(rebase_leaves(node.left, rebase), rebase_leaves(node.right, rebase))
      when Formula::Or
        Formula::Or.new(rebase_leaves(node.left, rebase), rebase_leaves(node.right, rebase))
      else
        node
      end
    end
  end
end
