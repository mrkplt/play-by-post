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

  # The Display Name row's label: the saved name, or a placeholder when none
  # has been set yet.
  sig { returns(String) }
  def display_name_or_placeholder
    @model.display_name.presence || "Not set"
  end

  sig { returns(T::Boolean) }
  def hide_ooc?
    @model.hide_ooc?
  end

  # The per-user AI DISPLAY preference (AI Control Plane) — shown/tagged/hidden,
  # the sole per-user AI control (`hidden` opts the viewer out of seeing AI
  # content). See UserProfile#ai_display_preference.
  sig { returns(String) }
  def ai_display_preference
    @model.ai_display_preference
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
