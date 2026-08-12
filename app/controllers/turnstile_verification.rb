# typed: strict

# Controller mixin enforcing a Turnstile token on a form submit. Include it and
# wire `before_action :verify_turnstile!`. A form controller overrides
# `turnstile_verification_failed` to re-render its form instead of the default 403.
module TurnstileVerification
  extend T::Sig

  # T.bind resolves the controller methods for Sorbet; Devise's incomplete RBI
  # ancestry rules out a static requires_ancestor constraint.
  sig { void }
  def verify_turnstile!
    T.bind(self, T.all(ActionController::Base, TurnstileVerification))
    return unless Turnstile.enabled?

    token = params["cf-turnstile-response"]
    return if TurnstileVerifier.verify(token: token, remote_ip: request.remote_ip)

    turnstile_verification_failed
  end

  private

  sig { void }
  def turnstile_verification_failed
    T.bind(self, ActionController::Base)
    head :forbidden
  end
end
