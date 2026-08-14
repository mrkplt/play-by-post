# typed: strict
# frozen_string_literal: true

# The current user's profile lookup ProfilesController's every action shares.
# A plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns").
#
# Looked up on demand rather than cached in a before_action ivar:
# bin/check-view-layering's controller_ivars scan reads every ivar a
# controller (or a module a controller includes) writes, regardless of
# visibility or whether a view ever reads it — so memoizing into `@profile`
# here would report the same raw-model violation a before_action shape did.
#
# `build_user_profile` returns a NEW unsaved record on every call when the
# user has none yet, so unlike game/scene/character lookups elsewhere, this
# one is not safe to re-call mid-action: ProfilesController#update relies on
# the same object across `profile.display_name = ...` and `profile.save`.
# Each caller must fetch this once into a local and thread it through
# explicitly (see ProfilesController) rather than relying on this method to
# remember anything between calls.
module ProfileScoped
  extend T::Sig
  include RequestMemo

  private

  sig { returns(UserProfile) }
  def profile
    T.bind(self, T.all(ActionController::Base, ProfileScoped))
    memo(:profile) { current_user.user_profile || current_user.build_user_profile }
  end
end
