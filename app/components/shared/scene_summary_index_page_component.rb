# typed: strict

class Shared::SceneSummaryIndexPageComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, summaries: T.untyped, pagy: T.untyped).void }
  def initialize(game:, summaries:, pagy:)
    @game = T.let(game, Game)
    @summaries = T.let(summaries, T.untyped)
    @pagy = T.let(pagy, T.untyped)
  end

  sig { returns(T::Boolean) }
  def summaries_empty?
    @summaries.empty?
  end
end
