# typed: strict
# frozen_string_literal: true

# The game/scene/post lookup PostsController's every action shares. A plain
# module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns").
#
# Memoized through RequestMemo rather than a `@game`/`@scene`/`@post` ivar.
# Rails copies controller ivars into the view, so those would be view-facing
# raw models and R1 rightly rejects them — but they still need memoizing:
# `post` resolves through `scene` through `game`, and posts#update asks for
# them repeatedly, so fresh lookups cost 28 queries against 17.
# `post` reads `params[:id]`, so only call it from actions that route through
# it (`edit`/`update`/`mark_read`) — the others (`create`/`save_draft`/
# `discard_draft`) have no `:id` param and build/find their own post.
module PostScoped
  extend T::Sig
  include RequestMemo

  private

  sig { returns(Game) }
  def game
    T.bind(self, T.all(ActionController::Base, PostScoped))
    memo(:game) { Game.find_by!(slug: params[:game_id]) }
  end

  sig { returns(Scene) }
  def scene
    T.bind(self, T.all(ActionController::Base, PostScoped))
    memo(:scene) { game.scenes.find(params[:scene_id]) }
  end

  sig { returns(Post) }
  def post
    T.bind(self, T.all(ActionController::Base, PostScoped))
    memo(:post) { scene.posts.find(params[:id]) }
  end
end
