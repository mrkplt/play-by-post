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
    @export_all_rate_limited = GameExportRequest.rate_limited?(current_user, nil)
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
  def export_all
    if GameExportRequest.rate_limited?(current_user, nil)
      redirect_to profile_path, alert: "An all-games export was requested recently. Please wait 24 hours before requesting another."
      return
    end

    request = GameExportRequest.create!(user: current_user, game: nil)
    ExportJob.perform_later(request.id)

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end
end
