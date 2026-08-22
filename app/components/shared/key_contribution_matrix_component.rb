# typed: strict

# The profile's "fund AI for your games" matrix: for each game the person
# belongs to, a toggle per pool-fundable AI feature saying whether their own
# OpenRouter key funds that feature for that game. Offering/revoking is their
# own consent — a game does not own a key; a person makes theirs available.
#
# Takes presentation-ready rows (KeyContributionRowPresenter), each exposing a
# game `name` and per-feature `cells` — self-describing toggles that own their
# own verb/params/state/label, so this component is pure markup.
class Shared::KeyContributionMatrixComponent < ApplicationComponent
  extend T::Sig

  # One matrix cell — a self-describing toggle the template renders without
  # branching. Two subtypes: Offered (the viewer already funds this feature for
  # this game; revoke) and Available (they can offer their key; fund). Each owns
  # its verb/params/switch-state/aria/path. A component-ready value object, not
  # a presenter (a presenter transforms a model; this is already display data),
  # so it lives with the component that renders it.
  class Cell
    extend T::Sig
    extend T::Helpers
    abstract!

    sig { returns(String) }
    attr_reader :label

    sig { returns(String) }
    attr_reader :path

    sig { params(label: String, feature: String, path: String).void }
    def initialize(label:, feature:, path:)
      @label = label
      @feature = feature
      @path = path
    end

    sig { abstract.returns(Symbol) }
    def http_method; end

    sig { abstract.returns(T::Hash[Symbol, String]) }
    def params; end

    sig { abstract.returns(Symbol) }
    def switch_state; end

    sig { abstract.returns(String) }
    def aria_label; end
  end

  # Already funded: revoke with DELETE (feature rides in the path), switch on.
  class Offered < Cell
    sig { override.returns(Symbol) }
    def http_method = :delete

    sig { override.returns(T::Hash[Symbol, String]) }
    def params = {}

    sig { override.returns(Symbol) }
    def switch_state = :on

    sig { override.returns(String) }
    def aria_label = "Stop funding #{label} with your key"
  end

  # Not yet funded: offer with POST carrying the feature name, switch off.
  class Available < Cell
    sig { override.returns(Symbol) }
    def http_method = :post

    sig { override.returns(T::Hash[Symbol, String]) }
    def params = { feature: @feature }

    sig { override.returns(Symbol) }
    def switch_state = :off

    sig { override.returns(String) }
    def aria_label = "Fund #{label} with your key"
  end

  sig { params(rows: T::Array[KeyContributionRowPresenter]).void }
  def initialize(rows:)
    @rows = rows
  end

  sig { returns(T::Array[KeyContributionRowPresenter]) }
  attr_reader :rows

  sig { returns(T::Boolean) }
  def any_games?
    rows.any?
  end
end
