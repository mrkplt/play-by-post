# typed: strict

class ProfilesController < ApplicationController
  extend T::Sig
  include ProfileScoped

  after_action :verify_authorized

  sig { void }
  def show
    current_profile = profile
    authorize current_profile
    @user_presenter = T.let(UserPresenter.new(current_user), T.nilable(UserPresenter))
    @feed_rows = T.let(T.must(@user_presenter).feed_rows(urls: self), T.nilable(T::Array[GameFeedRowPresenter]))
    assign_profile_presenter(current_profile)
  end

  sig { void }
  def edit
    current_profile = profile
    authorize current_profile
    assign_profile_presenter(current_profile)
  end

  sig { void }
  def update
    current_profile = profile
    authorize current_profile
    current_profile.display_name = params[:user_profile][:display_name]

    if current_profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      assign_profile_presenter(current_profile)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_hide_ooc
    current_profile = profile
    authorize current_profile, :manage?
    current_profile.update!(hide_ooc: !current_profile.hide_ooc?)
    head :ok
  end

  sig { void }
  def export_all
    authorize profile, :manage?
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

  sig { params(current_profile: UserProfile).void }
  def assign_profile_presenter(current_profile)
    @profile_presenter = T.let(UserProfilePresenter.new(current_profile), T.nilable(UserProfilePresenter))
  end
end
