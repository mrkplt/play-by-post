# typed: true

class ProfilesController < ApplicationController
  extend T::Sig

  sig { void }
  def show
    @profile = current_user.user_profile || current_user.build_user_profile
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(:game)
      .order("games.name")
    @export_all_receipt = GameExportRequest.valid_receipt_for(current_user, nil)
  end

  sig { void }
  def edit
    @profile = current_user.user_profile || current_user.build_user_profile
  end

  sig { void }
  def update
    @profile = current_user.user_profile || current_user.build_user_profile
    @profile.display_name = params[:user_profile][:display_name]

    if @profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    profile = current_user.user_profile || current_user.build_user_profile
    profile.update!(hide_ooc: !profile.hide_ooc?)
    head :ok
  end

  sig { void }
  def generate_rss_token
    current_user.rss_token&.destroy
    current_user.create_rss_token!
    redirect_to profile_path, notice: "RSS token generated."
  end

  sig { void }
  def revoke_rss_token
    current_user.rss_token&.destroy
    redirect_to profile_path, notice: "RSS token revoked."
  end

  sig { void }
  def export_all
    receipt = GameExportRequest.valid_receipt_for(current_user, nil)

    if receipt
      ExportDelivery.email_download_link(receipt)
    else
      request = GameExportRequest.create!(user: current_user, game: nil)
      ExportJob.perform_later(request.id)
    end

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end
end
