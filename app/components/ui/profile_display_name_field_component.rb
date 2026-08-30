# typed: strict

# The Display Name row's control on the Profile screen: view mode (name +
# Edit) and edit mode (text field + Save/Cancel) both render, and
# inline_edit_field (Stimulus) toggles which is visible — no navigation to a
# separate edit page. Save posts to `update_path` (ProfilesController#update);
# the controller answers with a Turbo Stream that swaps this control (by
# CONTROL_ID) back to view mode plus a toast, mirroring
# Ui::ProfileAiDisplayPreferenceControlComponent. On a validation failure the
# controller re-renders this same component with `editing: true` so the field
# stays open with its error message, instead of dropping back to view mode.
class Ui::ProfileDisplayNameFieldComponent < ApplicationComponent
  extend T::Sig

  # Stable id the Turbo Stream reply targets to replace the control after save
  # (see ProfilesController#update).
  CONTROL_ID = T.let("profile_display_name_field", String)

  FORM_ID = T.let("profile_display_name_form", String)

  sig { params(profile: UserProfilePresenter, update_url: String, editing: T::Boolean).void }
  def initialize(profile:, update_url:, editing: false)
    @profile = profile
    @update_url = update_url
    @editing = editing
  end

  sig { returns(String) }
  attr_reader :update_url

  sig { returns(String) }
  def display_name
    @profile.display_name_or_placeholder
  end

  sig { returns(T.nilable(String)) }
  def display_name_value
    @profile.display_name
  end

  sig { returns(T::Boolean) }
  def editing?
    @editing || errors?
  end

  sig { returns(T::Boolean) }
  def errors?
    @profile.display_name_errors?
  end

  sig { returns(T.nilable(String)) }
  def error_message
    @profile.display_name_error_message
  end
end
