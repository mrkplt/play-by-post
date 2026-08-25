# typed: strict

# The profile's "Your Games" section — the person's per-game control plane.
# One card per game membership, holding every control the viewer owns *about*
# that game: the RSS feed token, the API token, and (when they have a BYOK key
# of their own) the AI-funding toggles. Replaces the three feature-first
# sections (RSS Feeds / API tokens / Fund AI for your games) that each
# re-listed the same games.
#
# Takes presentation-ready rows (GameControlRowPresenter); `funding:` says
# whether the funding row renders at all — key presence is a viewer-level fact,
# so it arrives as a flag rather than per row.
class Shared::GameControlsComponent < ApplicationComponent
  extend T::Sig

  # One funding cell — a self-describing toggle the template renders without
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

  # One credential row of a game card: the row label, the per-game presenter
  # behind it (GameFeedRowPresenter / ApiTokenRowPresenter — the shared
  # token?/secret_value/create_path/revoke_path interface), and the labels and
  # scope the create/reveal control needs.
  class TokenRow < T::Struct
    const :label, String
    const :row, T.untyped
    const :secret_label, String
    const :create_label, String
    const :scope, String
  end

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])
  LAST_TOKEN_ROW_INDEX = 1

  sig { params(rows: T::Array[GameControlRowPresenter], funding: T::Boolean).void }
  def initialize(rows:, funding:)
    @rows = rows
    @funding = funding
  end

  sig { returns(T::Array[GameControlRowPresenter]) }
  attr_reader :rows

  sig { returns(T::Boolean) }
  def any_games?
    rows.any?
  end

  sig { returns(T::Boolean) }
  def funding?
    @funding
  end

  sig { params(game_row: GameControlRowPresenter).returns(T::Array[TokenRow]) }
  def token_rows(game_row)
    [
      TokenRow.new(label: "RSS feed", row: game_row.feed, secret_label: "Feed URL",
                   create_label: "Create feed", scope: "rss"),
      TokenRow.new(label: "API token", row: game_row.api, secret_label: "API token",
                   create_label: "Create token", scope: "api")
    ]
  end

  # The funding row (when shown) is always the card's last row, so a token row
  # is :last only when it is the final one and no funding row follows.
  sig { params(index: Integer).returns(Symbol) }
  def token_row_position(index)
    POSITIONS.fetch(!funding? && index == LAST_TOKEN_ROW_INDEX)
  end
end
