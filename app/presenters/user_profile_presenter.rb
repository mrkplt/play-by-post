# typed: strict

# View model for the profile display-name form: the current validation state
# of the display_name field. Everything form_with needs to build the update
# route (to_param, persisted?, model_name) is delegated straight through
# SimpleDelegator, so the presenter itself only has to answer the questions
# ERB used to ask the model directly.
class UserProfilePresenter < BasePresenter
  extend T::Sig

  sig { params(model: UserProfile, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def display_name_errors?
    @model.errors[:display_name].any?
  end

  sig { returns(T.nilable(String)) }
  def display_name_error_message
    @model.errors[:display_name].first
  end
end
