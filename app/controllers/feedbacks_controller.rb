# typed: true

class FeedbacksController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  sig { void }
  def create
    feedback = current_user.feedbacks.build(feedback_params)
    authorize feedback

    if feedback.save
      redirect_back fallback_location: root_path, notice: "Thanks for your feedback!"
    else
      redirect_back fallback_location: root_path, alert: "Feedback can't be blank."
    end
  end

  private

  sig { returns(ActionController::Parameters) }
  def feedback_params
    params.require(:feedback).permit(:body, :url)
  end
end
