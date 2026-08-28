# typed: strict

class ProfilesController < ApplicationController
  extend T::Sig
  include ProfileScoped
  include InPlaceRender

  after_action :verify_authorized

  sig { void }
  def show
    current_profile = profile
    authorize current_profile
    @user_presenter = T.let(UserPresenter.new(current_user, helpers: helpers), T.nilable(UserPresenter))
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

  # The per-user AI DISPLAY preference (AI Control Plane): the sole per-user AI
  # control — its `hidden` state opts the viewer out of seeing AI content. This
  # controls how the viewer's own client renders AI-generated assets they
  # encounter, not whether their games may generate them (that is the GM's
  # game-level Game#ai_summaries_enabled). See UserProfile#ai_display_preference
  # and SceneSummary.visible_to.
  sig { void }
  def update_ai_display_preference
    current_profile = profile
    authorize current_profile, :manage?
    current_profile.update!(ai_display_preference: ai_display_preference_param)
    render_ai_display_preference(current_profile)
  end

  # Fire-and-forget: the export is emailed, so there is nothing on the page to
  # re-render — a toast in place is the whole response, no full profile reload.
  sig { void }
  def export_all
    authorize profile, :manage?
    ExportDelivery.request!(user: current_user, game: nil)

    flash.now[:notice] = "Export requested — you'll receive an email shortly."
    render turbo_stream: toast_stream
  end

  private

  # Persist-in-place: swap the control for its new active state and drop a
  # confirmation toast via Turbo Stream, so a choice sticks with no full-page
  # reload (the reload was jumping the profile's scroll position). flash.now,
  # not flash: nothing redirects, so a persisted flash would leak onto the next
  # full page load. Mirrors Profiles::ByokKeysController#render_pending.
  sig { params(current_profile: UserProfile).void }
  def render_ai_display_preference(current_profile)
    flash.now[:notice] = "AI display preference updated."
    render turbo_stream: [
      turbo_stream.replace(
        Ui::ProfileAiDisplayPreferenceControlComponent::CONTROL_ID,
        Ui::ProfileAiDisplayPreferenceControlComponent.new(
          preference: current_profile.ai_display_preference,
          update_url: update_ai_display_preference_profile_path
        )
      ),
      toast_stream
    ]
  end

  sig { params(current_profile: UserProfile).void }
  def assign_profile_presenter(current_profile)
    @profile_presenter = T.let(UserProfilePresenter.new(current_profile), T.nilable(UserProfilePresenter))
  end

  # UserProfile#update! raises ArgumentError on an unrecognized enum value —
  # no separate inclusion check needed here.
  sig { returns(String) }
  def ai_display_preference_param
    params.require(:ai_display_preference)
  end
end
