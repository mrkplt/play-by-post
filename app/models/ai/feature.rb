# typed: strict

# The single source of truth for every AI feature the app has, and its funding
# character. An AI feature is one of three levels:
#
#   :game       — a shared, game-level output (e.g. a scene summary). Eligible
#                 for GROUP contribution: funded from the game's pool of
#                 GameKeyAuthorizations. This is what makes a feature
#                 "pool-fundable".
#   :personal   — an individual's own output, funded by that person's own key
#                 only, never the pool. (None ship yet; Character Portraits #19
#                 is the expected first one.)
#   :app_infra  — the app's own infrastructure spend on the app's OpenRouter key
#                 (e.g. inbound-email extraction), entirely outside BYOK. Never
#                 game/personal, never pool-fundable.
#
# Everything that needs to know "is this feature game-level / may a person's key
# fund it for a game" asks HERE — AiUsage validates its `feature` against the
# registry, and GameKeyAuthorization only accepts pool-fundable feature names.
module Ai
  class Feature
    extend T::Sig

    LEVELS = T.let(%i[game personal app_infra].freeze, T::Array[Symbol])

    sig { returns(String) }
    attr_reader :name

    sig { returns(Symbol) }
    attr_reader :level

    sig { params(name: String, level: Symbol).void }
    def initialize(name:, level:)
      @name = name
      @level = level
    end

    sig { returns(T::Boolean) }
    def game_level?
      level == :game
    end

    sig { returns(T::Boolean) }
    def personal_level?
      level == :personal
    end

    # A feature draws from a game's contribution pool exactly when it is a
    # game-level output — a shared asset the game collectively funds.
    sig { returns(T::Boolean) }
    def pool_fundable?
      game_level?
    end

    REGISTRY = T.let(
      [
        new(name: "scene_summary", level: :game),
        new(name: "inbound_email", level: :app_infra)
      ].to_h { |feature| [ feature.name, feature ] }.freeze,
      T::Hash[String, Feature]
    )

    class << self
      extend T::Sig

      # The feature for a known name, else KeyError — callers naming a feature
      # are expected to name a real one, so an unknown name is a bug, not a
      # branch (fail-closed).
      sig { params(name: String).returns(Feature) }
      def fetch(name)
        REGISTRY.fetch(name)
      end

      sig { params(name: String).returns(T::Boolean) }
      def known?(name)
        REGISTRY.key?(name)
      end

      sig { returns(T::Array[String]) }
      def names
        REGISTRY.keys
      end

      # Whether a (possibly unknown) feature name may be funded from a game's
      # pool. Unknown names are not pool-fundable rather than raising, so
      # validation call sites read as a plain predicate.
      sig { params(name: String).returns(T::Boolean) }
      def pool_fundable?(name)
        known?(name) && fetch(name).pool_fundable?
      end

      # The feature names a person may authorize a key to fund for a game — the
      # authorization surface. Only pool-fundable (game-level) features.
      sig { returns(T::Array[String]) }
      def pool_fundable_names
        REGISTRY.values.select(&:pool_fundable?).map(&:name)
      end
    end
  end
end
