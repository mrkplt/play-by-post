# typed: strict

# The profile's "API tokens" section: one row per game the user belongs to, each
# offering to create an api-scoped token or — when one exists — showing the
# copyable raw token value (via Ui::SecretFieldComponent) and a revoke control.
# Takes the rows already resolved to ApiTokenRowPresenters, so the component only
# lays out what it is handed. Parallels Shared::RssFeedsSectionComponent.
class Shared::ApiTokensSectionComponent < ApplicationComponent
  extend T::Sig

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])

  sig { params(rows: T::Array[ApiTokenRowPresenter]).void }
  def initialize(rows:)
    @rows = T.let(rows, T::Array[ApiTokenRowPresenter])
  end

  sig { returns(T::Array[ApiTokenRowPresenter]) }
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
