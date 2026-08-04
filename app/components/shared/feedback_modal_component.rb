# typed: strict

# The feedback collection modal opened from the nav drawer's "Send Feedback"
# button. It holds a textarea, a submit, and a cancel, plus a hidden field that
# the `feedback` Stimulus controller fills with the current page URL on open.
#
# Rendered outside the nav-drawer `<aside>` (which is CSS-transformed off-screen
# on mobile, breaking `position: fixed` for descendants) as a sibling, so the
# fixed-position overlay is measured against the viewport. The submitter is
# recorded server-side from the session, not carried in the form.
class Shared::FeedbackModalComponent < ApplicationComponent
  extend T::Sig

  sig { returns(String) }
  def submit_path
    helpers.feedbacks_path
  end
end
