# typed: strict

# The profile's "RSS Feeds" section: one row per game the user belongs to, each
# offering to create a feed token or — when one exists — showing the copyable
# feed URL (via Ui::SecretFieldComponent) and a revoke control. Takes the rows
# already resolved to GameFeedRowPresenters, so the component only lays out
# what it is handed.
class Shared::RssFeedsSectionComponent < ApplicationComponent
  extend T::Sig

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])

  sig { params(rows: T::Array[GameFeedRowPresenter]).void }
  def initialize(rows:)
    @rows = T.let(rows, T::Array[GameFeedRowPresenter])
  end

  sig { returns(T::Array[GameFeedRowPresenter]) }
  attr_reader :rows

  sig { returns(T::Boolean) }
  def any_games?
    @rows.any?
  end

  sig { params(index: Integer).returns(Symbol) }
  def row_position(index)
    POSITIONS.fetch(index == @rows.length - 1)
  end
end
