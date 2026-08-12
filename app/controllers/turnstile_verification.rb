# typed: strict

# Controller mixin that enforces a Cloudflare Turnstile token on a form submit.
#
# Plain Ruby module, `include`d into a controller (not an ActiveSupport::Concern)
# — matching this app's convention of including plain modules (see Pagy/Pundit in
# ApplicationController). Inside the controller, `include TurnstileVerification`
# and then wire it as a filter:
#
#     before_action :verify_turnstile!, only: :create
#
# When Turnstile is disabled (test env, or a build without keys) the check is a
# no-op, so forms and dev quick-login flows don't have to carry a token. When a
# token is present it is verified via TurnstileVerifier, which fails **open** if
# Cloudflare is unreachable (rack-attack rate-limiting is the abuse backstop).
#
# On a genuine failed check, the default response is a bare 403. A controller
# that renders a form should override `turnstile_verification_failed` to
# re-render that form so the happy and error paths render the same view.
module TurnstileVerification
  extend T::Sig

  # This mixin is only included into controllers; bind `self` to
  # ActionController::Base so Sorbet resolves the controller methods it calls
  # (params/request/head). Devise's incomplete RBI ancestry makes a static
  # `requires_ancestor` constraint impractical here, so we bind at the call site.
  sig { void }
  def verify_turnstile!
    T.bind(self, T.all(ActionController::Base, TurnstileVerification))
    return unless Turnstile.enabled?

    token = params["cf-turnstile-response"]
    return if TurnstileVerifier.verify(token: token, remote_ip: request.remote_ip)

    turnstile_verification_failed
  end

  private

  # Default failure response; override in a form controller to re-render the form.
  sig { void }
  def turnstile_verification_failed
    T.bind(self, ActionController::Base)
    head :forbidden
  end
end
