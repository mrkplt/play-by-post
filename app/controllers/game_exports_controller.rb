# typed: true

class GameExportsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_export_access!

  sig { void }
  def create
    if GameExportRequest.rate_limited?(current_user, @game)
      redirect_to game_path(@game), alert: "An export was requested recently. Please wait 24 hours before requesting another."
      return
    end

    request = GameExportRequest.create!(user: current_user, game: @game)
    ExportJob.perform_later(request.id)

    redirect_to game_path(@game), notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_export_access!
    membership = @game.member_for(current_user)
    return if membership&.active? || membership&.game_master? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to export this game."
  end
end
