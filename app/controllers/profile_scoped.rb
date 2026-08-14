# typed: strict
# frozen_string_literal: true

# The current user's profile lookup ProfilesController's every action shares.
# A plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns"). `||=` rather than `=`: each request builds a
# fresh controller (so this still runs exactly once), and the memoized form is
# the only ivar-write shape this project's ivar-hygiene gate treats as
# initialization rather than mutation.
#
# Memoization matters here beyond caching a query: `build_user_profile`
# returns a new unsaved record on every call when the user has none yet, so
# an unmemoized `profile` would silently drop the `update` action's
# assignment between `profile.display_name = ...` and `profile.save`.
module ProfileScoped
  extend T::Sig

  private

  sig { returns(UserProfile) }
  def profile
    T.bind(self, T.all(ActionController::Base, ProfileScoped))
    @profile ||= T.let(current_user.user_profile || current_user.build_user_profile, T.nilable(UserProfile))
  end
end
