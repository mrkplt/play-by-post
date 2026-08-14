# typed: strict
# frozen_string_literal: true

# The game/scene lookup ScenesController's every action shares: a plain
# module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns"), so the before_action wiring stays visible in the
# controller itself. `||=` rather than `=`: each request builds a fresh
# controller (so this still runs exactly once), and the memoized form is the
# only ivar-write shape this project's ivar-hygiene gate treats as
# initialization rather than mutation.
module SceneScoped
  extend T::Sig

  private

  sig { void }
  def set_game
    T.bind(self, T.all(ActionController::Base, SceneScoped))
    @game ||= T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    T.bind(self, T.all(ActionController::Base, SceneScoped))
    @scene ||= T.let(game.scenes.find(params[:id]), T.nilable(Scene))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Scene) }
  def scene
    T.must(@scene)
  end

  # The scene ScenesController#new/#create build and validate against —
  # memoized so the error-path re-render in #create sees the same
  # (now-invalid) record the save was attempted on, not a fresh one.
  sig { returns(Scene) }
  def new_scene
    T.bind(self, T.all(ActionController::Base, SceneScoped))
    @new_scene ||= T.let(game.scenes.new, T.nilable(Scene))
  end
end
