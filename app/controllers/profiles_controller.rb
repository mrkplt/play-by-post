# typed: strict

class ProfilesController < ApplicationController
  extend T::Sig
  include ProfileScoped

  after_action :verify_authorized

  sig { void }
  def show
    current_profile = profile
    authorize current_profile
    @user_presenter = T.let(UserPresenter.new(current_user, helpers: helpers), T.nilable(UserPresenter))
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

    if current_profile.update_display_name(params[:user_profile][:display_name])
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

  # The per-user AI consent gate (AI Control Plane): generation for this
  # user's games still requires the game's own ai_summaries_enabled toggle —
  # see SceneResolution#call.
  sig { void }
  def toggle_ai_summaries_consent
    current_profile = profile
    authorize current_profile, :manage?
    current_profile.update!(ai_summaries_consent: !current_profile.ai_summaries_consent?)
    redirect_to profile_path, notice: ai_summaries_consent_notice(current_profile)
  end

  sig { void }
  def export_all
    authorize profile, :manage?
    ExportDelivery.request!(user: current_user, game: nil)

    redirect_to profile_path, notice: "Export requested — you'll receive an email shortly."
  end

  private

  sig { params(current_profile: UserProfile).void }
  def assign_profile_presenter(current_profile)
    @profile_presenter = T.let(UserProfilePresenter.new(current_profile), T.nilable(UserProfilePresenter))
  end

  sig { params(current_profile: UserProfile).returns(String) }
  def ai_summaries_consent_notice(current_profile)
    current_profile.ai_summaries_consent? ? "AI scene summaries enabled for your games." : "AI scene summaries disabled for your games."
  end
end
