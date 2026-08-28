# typed: strict

class GameExportsController < ApplicationController
  extend T::Sig
  include InPlaceRender

  before_action :require_export_access!
  after_action :verify_authorized

  # Fire-and-forget: the export is emailed, so there is nothing on the page to
  # re-render — a toast in place is the whole response, matching profiles#export_all
  # (the identical operation), no full game reload.
  sig { void }
  def create
    authorize game, :export?
    ExportDelivery.request!(user: current_user, game: game)

    flash_now(notice: "Export requested — you'll receive an email shortly.")
    render turbo_stream: toast_stream
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
