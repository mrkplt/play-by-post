# typed: true

class GameExportsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_export_access!

  sig { void }
  def create
    receipt = GameExportRequest.valid_receipt_for(current_user, @game)

    if receipt
      # A successful export already exists within the receipt window — resend its
      # download link instead of reprocessing.
      ExportDelivery.email_download_link(receipt)
    else
      request = GameExportRequest.create!(user: current_user, game: @game)
      ExportJob.perform_later(request.id)
    end

    redirect_to game_path(@game), notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_export_access!
    return if @game.viewable_by?(current_user)

    redirect_to root_path, alert: "You do not have access to export this game."
  end
end
