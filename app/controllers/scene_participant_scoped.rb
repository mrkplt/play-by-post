# typed: strict
# frozen_string_literal: true

# The game/scene lookup SceneParticipantsController's every action shares —
# nested under a scene as `resource :participants`, so the scene comes from
# `params[:scene_id]`, not `params[:id]` (that param names this resource's
# own — nonexistent, since it is a singular resource — id). A plain module
# included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns"). `requires_ancestor ApplicationController` lets Sorbet
# resolve the controller methods (params, and RequestMemo#memo) without a
# per-method T.bind.
#
# Looked up on demand and memoized through RequestMemo rather than a
# `@game`/`@scene` ivar, which Rails would copy into the view and the
# controller_ivars scan would reject.
module SceneParticipantScoped
  extend T::Sig
  extend T::Helpers
  include RequestMemo

  requires_ancestor { ApplicationController }

  private

  sig { returns(Game) }
  def game
    memo(:game) { Game.find_by!(slug: params[:game_id]) }
  end

  sig { returns(Scene) }
  def scene
    memo(:scene) { game.scenes.find(params[:scene_id]) }
  end
end
