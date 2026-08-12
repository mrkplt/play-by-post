# typed: false

# Edge rate-limiting — the infrastructure-tier hard stop (coarse IP/token/email
# floods, before Rails). House rule: per-actor application quotas belong in
# Rails 8.1's controller-level `rate_limit`, not here. Backed by Solid Cache;
# disabled in test (throttle specs enable it and swap in a MemoryStore).
class Rack::Attack
  self.cache.store = Rails.cache

  # Sign-in: coarse per-IP flood limit + tighter per-email (the spam vector).
  throttle("sign_in/ip", limit: 10, period: 3.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("sign_in/email", limit: 5, period: 3.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Must normalize exactly as Users::SessionsController#create does, or
      # varying case/whitespace bypasses the limit.
      email = (req.params.dig("user", "email") || req.params["email"]).to_s.strip.downcase
      email.presence
    end
  end

  # Invitation accept: a bare GET link (no Turnstile), so throttling is its only
  # guard — per-IP against scanners, per-token against guessing.
  throttle("invite_accept/ip", limit: 20, period: 1.minute) do |req|
    req.ip if invitation_accept?(req)
  end

  throttle("invite_accept/token", limit: 10, period: 1.minute) do |req|
    invite_token(req) if invitation_accept?(req)
  end

  # Inbound webhook: secondary to the Svix signature; tighter since Resend's
  # senders are few.
  throttle("inbound_email/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/mail/inbound" && req.post?
  end

  INVITE_ACCEPT_PATH = %r{\A/invitations/(?<token>[^/]+)/accept\z}

  def self.invitation_accept?(req)
    req.get? && INVITE_ACCEPT_PATH.match?(req.path)
  end

  def self.invite_token(req)
    INVITE_ACCEPT_PATH.match(req.path)&.[](:token)
  end

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
