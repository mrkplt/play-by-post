# typed: strict

# The "continued in" links row on a scene screen — child scenes branched off
# this one. Renders nothing when there are no child scenes.
class Shared::ChildSceneListComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, child_scenes: T::Array[Scene]).void }
  def initialize(game:, child_scenes:)
    @game = T.let(game, Game)
    @child_scenes = T.let(child_scenes, T::Array[Scene])
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[Scene]) }
  attr_reader :child_scenes

  sig { returns(T::Boolean) }
  def any?
    @child_scenes.any?
  end
end
