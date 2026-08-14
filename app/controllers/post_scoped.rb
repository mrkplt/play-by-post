# typed: strict
# frozen_string_literal: true

# The game/scene/post lookup PostsController's every action shares. A plain
# module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns"). `||=` rather than `=`: each request builds a fresh
# controller (so this still runs exactly once), and the memoized form is the
# only ivar-write shape this project's ivar-hygiene gate treats as
# initialization rather than mutation.
module PostScoped
  extend T::Sig

  private

  sig { void }
  def set_game
    T.bind(self, T.all(ActionController::Base, PostScoped))
    @game ||= T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    T.bind(self, T.all(ActionController::Base, PostScoped))
    @scene ||= T.let(T.must(@game).scenes.find(params[:scene_id]), T.nilable(Scene))
  end

  sig { void }
  def set_post
    T.bind(self, T.all(ActionController::Base, PostScoped))
    @post ||= T.let(T.must(@scene).posts.find(params[:id]), T.nilable(Post))
  end
end
