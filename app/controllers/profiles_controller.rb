# typed: true

class ProfilesController < ApplicationController
  extend T::Sig

  before_action :set_profile
  after_action :verify_authorized

  sig { void }
  def show
    authorize @profile
    @feed_rows = UserPresenter.new(current_user).feed_rows(urls: self)
    @export_all_receipt = GameExportRequest.valid_receipt_for(current_user, nil)
  end

  sig { void }
  def edit
    authorize @profile
    @profile_presenter = UserProfilePresenter.new(@profile)
  end

  sig { void }
  def update
    authorize @profile
    @profile.display_name = params[:user_profile][:display_name]

    if @profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      @profile_presenter = UserProfilePresenter.new(@profile)
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
