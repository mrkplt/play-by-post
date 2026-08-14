# typed: strict

class ProfilesController < ApplicationController
  extend T::Sig

  before_action :set_profile
  after_action :verify_authorized

  sig { void }
  def show
    authorize @profile
    @user_presenter = T.let(UserPresenter.new(current_user), T.nilable(UserPresenter))
    @feed_rows = T.let(T.must(@user_presenter).feed_rows(urls: self), T.nilable(T::Array[GameFeedRowPresenter]))
  end

  sig { void }
  def edit
    authorize @profile
    @profile_presenter = T.let(UserProfilePresenter.new(T.must(@profile)), T.nilable(UserProfilePresenter))
  end

  sig { void }
  def update
    authorize @profile
    T.must(@profile).display_name = params[:user_profile][:display_name]

    if T.must(@profile).save
      redirect_to root_path, notice: "Display name saved."
    else
      @profile_presenter = T.let(UserProfilePresenter.new(T.must(@profile)), T.nilable(UserProfilePresenter))
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    authorize @profile, :manage?
    T.must(@profile).update!(hide_ooc: !T.must(@profile).hide_ooc?)
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
    @profile = T.let(current_user.user_profile || current_user.build_user_profile, T.nilable(UserProfile))
  end
end
