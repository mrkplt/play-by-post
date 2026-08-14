# typed: strict
# frozen_string_literal: true

# The game/scene lookup ScenesController's every action shares: a plain
# module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns").
#
# Looked up on demand rather than cached in a before_action ivar:
# bin/check-view-layering's controller_ivars scan reads every ivar a
# controller (or a module a controller includes) writes, regardless of
# visibility or whether a view ever reads it — so memoizing into
# `@game`/`@scene` here would report the same raw-model violation the
# before_action shape did. Neither is mutated before use, so a fresh lookup
# per call is behaviorally identical to a memoized one, just an extra query.
module SceneScoped
  extend T::Sig

  private

  sig { returns(Game) }
  def game
    T.bind(self, T.all(ActionController::Base, SceneScoped))
    Game.find(params[:game_id])
  end

  sig { returns(Scene) }
  def scene
    T.bind(self, T.all(ActionController::Base, SceneScoped))
    game.scenes.find(params[:id])
  end
end
