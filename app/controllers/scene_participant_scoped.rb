# typed: strict
# frozen_string_literal: true

# The game/scene lookup SceneParticipantsController's every action shares —
# nested under a scene as `resource :participants`, so the scene comes from
# `params[:scene_id]`, not `params[:id]` (that param names this resource's
# own — nonexistent, since it is a singular resource — id). A plain module
# included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not
# use Rails "concerns"), so the before_action wiring stays visible in the
# controller itself. `||=` rather than `=`: each request builds a fresh
# controller (so this still runs exactly once), and the memoized form is the
# only ivar-write shape this project's ivar-hygiene gate treats as
# initialization rather than mutation.
module SceneParticipantScoped
  extend T::Sig

  private

  sig { void }
  def set_game
    T.bind(self, T.all(ActionController::Base, SceneParticipantScoped))
    @game ||= T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    T.bind(self, T.all(ActionController::Base, SceneParticipantScoped))
    @scene ||= T.let(game.scenes.find(params[:scene_id]), T.nilable(Scene))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Scene) }
  def scene
    T.must(@scene)
  end
end
