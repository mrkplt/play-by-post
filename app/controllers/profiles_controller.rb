# typed: true

class ProfilesController < ApplicationController
  extend T::Sig

  before_action :set_profile
  after_action :verify_authorized

  sig { void }
  def show
    authorize @profile
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(:game)
      .order("games.name")
    @rss_tokens_by_game = current_user.api_tokens.where(scope: "rss").index_by(&:game_id)
    @export_all_receipt = GameExportRequest.valid_receipt_for(current_user, nil)
  end

  sig { void }
  def edit
    authorize @profile
  end

  sig { void }
  def update
    authorize @profile
    @profile.display_name = params[:user_profile][:display_name]

    if @profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    authorize @profile, :manage?
    @profile.update!(hide_ooc: !@profile.hide_ooc?)
    head :ok
  end

  sig { void }
  def export_all
    authorize @profile, :manage?
    receipt = GameExportRequest.valid_receipt_for(current_user, nil)

    if receipt
      ExportDelivery.email_download_link(receipt)
    else
      request = GameExportRequest.create!(user: current_user, game: nil)
      ExportJob.perform_later(request.id)
    end

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { void }
  def set_profile
    @profile = current_user.user_profile || current_user.build_user_profile
  end
end
