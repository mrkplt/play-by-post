# typed: strict
# frozen_string_literal: true

# The game/scene/post lookup PostsController's every action shares. A plain
# module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns").
#
# Looked up on demand rather than cached in a before_action ivar:
# bin/check-view-layering's controller_ivars scan reads every ivar a
# controller (or a module a controller includes) writes, regardless of
# visibility or whether a view ever reads it — so memoizing into
# `@game`/`@scene`/`@post` here would report the same raw-model violation the
# before_action shape did. None is mutated before use, so a fresh lookup per
# call is behaviorally identical to a memoized one, just an extra query.
# `post` reads `params[:id]`, so only call it from actions that route through
# it (`edit`/`update`/`mark_read`) — the others (`create`/`save_draft`/
# `discard_draft`) have no `:id` param and build/find their own post.
module PostScoped
  extend T::Sig

  private

  sig { returns(Game) }
  def game
    T.bind(self, T.all(ActionController::Base, PostScoped))
    Game.find(params[:game_id])
  end

  sig { returns(Scene) }
  def scene
    T.bind(self, T.all(ActionController::Base, PostScoped))
    game.scenes.find(params[:scene_id])
  end

  sig { returns(Post) }
  def post
    T.bind(self, T.all(ActionController::Base, PostScoped))
    scene.posts.find(params[:id])
  end
end
