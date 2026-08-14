# typed: strict
# frozen_string_literal: true

# The game/scene lookup SceneParticipantsController's every action shares —
# nested under a scene as `resource :participants`, so the scene comes from
# `params[:scene_id]`, not `params[:id]` (that param names this resource's
# own — nonexistent, since it is a singular resource — id). A plain module
# included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not
# use Rails "concerns").
#
# Looked up on demand rather than cached in a before_action ivar:
# bin/check-view-layering's controller_ivars scan reads every ivar a
# controller (or a module a controller includes) writes, regardless of
# visibility or whether a view ever reads it — so memoizing into
# `@game`/`@scene` here would report the same raw-model violation the
# before_action shape did. Neither is mutated before use, so a fresh lookup
# per call is behaviorally identical to a memoized one, just an extra query.
module SceneParticipantScoped
  extend T::Sig
  include RequestMemo

  private

  sig { returns(Game) }
  def game
    T.bind(self, T.all(ActionController::Base, SceneParticipantScoped))
    memo(:game) { Game.find(params[:game_id]) }
  end

  sig { returns(Scene) }
  def scene
    T.bind(self, T.all(ActionController::Base, SceneParticipantScoped))
    memo(:scene) { game.scenes.find(params[:scene_id]) }
  end
end
