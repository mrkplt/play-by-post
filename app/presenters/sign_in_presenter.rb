# typed: strict

# View model for the sign-in screen: which of its two states to show (the
# email form, or the "check your email" confirmation) — the boolean the
# controller previously handed the view directly as @email_sent.
class SignInPresenter < BasePresenter
  extend T::Sig

  sig { params(model: User, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def email_sent?
    @options.fetch(:email_sent, false)
  end
end
