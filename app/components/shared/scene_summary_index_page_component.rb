# typed: strict

class Shared::SceneSummaryIndexPageComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, summaries: T.untyped, pagy: T.untyped, is_gm: T::Boolean).void }
  def initialize(game:, summaries:, pagy:, is_gm:)
    @game = T.let(game, Game)
    @summaries = T.let(summaries, T.untyped)
    @pagy = T.let(pagy, T.untyped)
    @is_gm = T.let(is_gm, T::Boolean)
  end

  sig { returns(T::Boolean) }
  def is_gm?
    @is_gm
  end

  sig { returns(T::Boolean) }
  def summaries_empty?
    @summaries.empty?
  end
end
