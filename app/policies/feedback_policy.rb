# typed: true
# frozen_string_literal: true

# Feedback can be submitted by any signed-in user about the page they are on;
# there is no ownership or membership gate beyond authentication.
class FeedbackPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def create?
    user.present?
  end
end
