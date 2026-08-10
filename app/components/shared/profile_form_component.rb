# typed: strict

# The "Set your display name" form (profiles/edit) — a single-line identifier
# field, so no markdown toolbar/preview per the forms convention (this is a
# short label, not prose). Mirrors the page-action-buttons-in-footer pattern:
# the template only renders the field; Save/Cancel live in the caller's
# PageActions footer via form_id.
class Shared::ProfileFormComponent < ApplicationComponent
  extend T::Sig

  FORM_ID = "profile_edit_form"

  sig { params(profile: UserProfile).void }
  def initialize(profile:)
    @profile = T.let(profile, UserProfile)
  end

  sig { returns(UserProfile) }
  attr_reader :profile

  sig { returns(String) }
  def form_id
    FORM_ID
  end

  sig { returns(String) }
  def update_path
    helpers.profile_path
  end

  sig { returns(T::Boolean) }
  def errors?
    @profile.errors[:display_name].any?
  end

  sig { returns(T.nilable(String)) }
  def error_message
    @profile.errors[:display_name].first
  end
end
