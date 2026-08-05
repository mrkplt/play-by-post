# typed: strict

# The GM's "End Scene" resolve form, revealed by the End Scene button on the
# scene screen. The outcome is a markdown field: a formatting toolbar above the
# textarea and a live rendered preview below, matching every other prose field.
# Kept hidden until toggled; the toggle button targets this component's
# `resolve-form` id.
class Shared::SceneResolveFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, scene: Scene).void }
  def initialize(game:, scene:)
    @game = T.let(game, Game)
    @scene = T.let(scene, Scene)
  end

  sig { returns(String) }
  def resolve_path
    helpers.resolve_game_scene_path(@game, @scene)
  end
end
