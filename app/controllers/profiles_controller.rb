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
    assign_profile_presenter
  end

  sig { void }
  def update
    authorize @profile
    profile.display_name = params[:user_profile][:display_name]

    if profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      assign_profile_presenter
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    authorize @profile, :manage?
    profile.update!(hide_ooc: !profile.hide_ooc?)
    head :ok
  end

  sig { void }
  def export_all
    authorize @profile, :manage?
    deliver_export

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { void }
  def deliver_export
    receipt = GameExportRequest.valid_receipt_for(current_user, nil)

    if receipt
      ExportDelivery.email_download_link(receipt)
    else
      request = GameExportRequest.create!(user: current_user, game: nil)
      ExportJob.perform_later(request.id)
    end
  end

  sig { void }
  def assign_profile_presenter
    @profile_presenter = T.let(UserProfilePresenter.new(profile), T.nilable(UserProfilePresenter))
  end

  sig { void }
  def set_profile
    @profile = T.let(current_user.user_profile || current_user.build_user_profile, T.nilable(UserProfile))
  end

  sig { returns(UserProfile) }
  def profile
    T.must(@profile)
  end
end
