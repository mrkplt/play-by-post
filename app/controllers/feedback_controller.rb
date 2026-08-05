# typed: true

class FeedbackController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  # Submitted from the nav-drawer modal via fetch (see feedback_controller.js),
  # so the response stays on the page — a bare status, no redirect/re-render.
  sig { void }
  def create
    feedback = current_user.feedback.build(feedback_params)
    authorize feedback

    if feedback.save
      head :created
    else
      head :unprocessable_content
    end
  end

  private

  sig { returns(ActionController::Parameters) }
  def feedback_params
    params.require(:feedback).permit(:body, :url)
  end
end
