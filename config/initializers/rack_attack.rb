# typed: false

# rack-attack — infrastructure-tier, pre-application HARD STOP for abusive
# traffic. Runs as middleware before the request reaches Rails, so it sheds
# coarse IP/token/email floods cheaply, without touching app code.
#
# House rule (see context/2026-08-12-abuse-protection-plan.md): this edge layer
# is rack-attack; per-actor application quotas (e.g. requests/hour per API key)
# are reserved for Rails 8.1's controller-level `rate_limit`. This file is only
# the edge layer.
#
# Backed by the app's Solid Cache store (DB-backed, no Redis). Disabled in the
# test environment by default so unrelated specs aren't throttled; the throttle
# specs enable it explicitly and swap in a MemoryStore.
class Rack::Attack
  # Solid Cache — the app's configured cache store. rack-attack only needs
  # #increment and #write, both provided by ActiveSupport::Cache::Store.
  self.cache.store = Rails.cache

  ### Magic-link sign-in — POST /users/sign_in ###

  # Layered: a coarse per-IP flood limit plus a tighter per-email limit, because
  # email is the spam/enumeration vector (one IP can target many addresses, and
  # one address can be targeted from many IPs).
  throttle("sign_in/ip", limit: 10, period: 3.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("sign_in/email", limit: 5, period: 3.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize identically to Users::SessionsController#create
      # (params.dig(:user, :email) || params[:email], stripped + downcased) so a
      # bypass can't be crafted by varying case/whitespace.
      email = (req.params.dig("user", "email") || req.params["email"]).to_s.strip.downcase
      email.presence
    end
  end

  ### Invitation accept — GET /invitations/:token/accept ###

  # A bare GET link (no form → no Turnstile), so throttling is its only abuse
  # control. Per-IP catches a scanner; per-token caps guessing against a single
  # invitation.
  throttle("invite_accept/ip", limit: 20, period: 1.minute) do |req|
    req.ip if invitation_accept?(req)
  end

  throttle("invite_accept/token", limit: 10, period: 1.minute) do |req|
    invite_token(req) if invitation_accept?(req)
  end

  ### Inbound email webhook — POST /mail/inbound ###

  # Secondary defense behind the Svix signature (which stays the primary gate).
  # Tighter, per the abuse-protection plan: Resend's inbound senders are few, so
  # a low per-IP ceiling still won't drop legitimate traffic.
  throttle("inbound_email/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/mail/inbound" && req.post?
  end

  # GET /invitations/:token/accept — match the path shape and extract the token.
  INVITE_ACCEPT_PATH = %r{\A/invitations/(?<token>[^/]+)/accept\z}

  def self.invitation_accept?(req)
    req.get? && INVITE_ACCEPT_PATH.match?(req.path)
  end

  def self.invite_token(req)
    INVITE_ACCEPT_PATH.match(req.path)&.[](:token)
  end

  ### Throttled response ###

  # Bare, machine-readable 429 with a Retry-After. rack-attack is the hard stop;
  # the friendly, re-rendered form lives at the controller layer (Turnstile).
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"] || {}
    retry_after = (match_data[:period] || 60).to_s
    [
      429,
      { "content-type" => "text/plain", "retry-after" => retry_after },
      [ "Too many requests. Please retry after #{retry_after} seconds.\n" ]
    ]
  end
end

# Disabled in test by default; throttle specs opt in via `Rack::Attack.enabled = true`.
Rack::Attack.enabled = !Rails.env.test?
