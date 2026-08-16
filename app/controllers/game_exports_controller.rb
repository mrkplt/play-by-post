# typed: strict

class GameExportsController < ApplicationController
  extend T::Sig

  before_action :require_export_access!
  after_action :verify_authorized

  sig { void }
  def create
    authorize game, :export?
    ExportDelivery.request!(user: current_user, game: game)

    redirect_to game_path(game), notice: "Export requested — you'll receive an email shortly."
  end

  private

  # Looked up on demand rather than cached in a before_action ivar: this
  # controller renders no templates, so nothing needs it to persist as
  # request state.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { void }
  def require_export_access!
    return if policy(game).export?

    redirect_to root_path, alert: "You do not have access to export this game."
  end
end
