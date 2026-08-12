# typed: strict

require "net/http"

# Verifies a Cloudflare Turnstile token server-side against the siteverify API.
#
# Fail-open policy: rate-limiting (rack-attack) is the always-on abuse backstop,
# so if Cloudflare's siteverify is unreachable, times out, or returns something
# unparseable, this returns `true` (allow) rather than locking users out during a
# Cloudflare outage. It fails **closed** (returns `false`) only on the two cases
# that indicate an actual failed human check: a blank token, or a well-formed
# siteverify response that explicitly reports `success: false`.
class TurnstileVerifier
  extend T::Sig

  # Total budget for the siteverify round-trip. Short so a hung Cloudflare can't
  # stall a form submit — on timeout we fail open.
  OPEN_TIMEOUT = T.let(2, Integer)
  READ_TIMEOUT = T.let(3, Integer)

  sig { params(token: T.nilable(String), remote_ip: T.nilable(String)).returns(T::Boolean) }
  def self.verify(token:, remote_ip: nil)
    new(token: token, remote_ip: remote_ip).verify
  end

  sig { params(token: T.nilable(String), remote_ip: T.nilable(String)).void }
  def initialize(token:, remote_ip: nil)
    @token = token
    @remote_ip = remote_ip
  end

  sig { returns(T::Boolean) }
  def verify
    # A missing token is a failed check, not an outage — fail closed.
    return false if @token.blank?

    response = post_siteverify
    parse_success(response.body)
  rescue StandardError => e
    # Network error, timeout, DNS failure, etc. — fail open; the throttle covers us.
    Rails.logger.warn("Turnstile siteverify unreachable, failing open: #{e.class}: #{e.message}")
    true
  end

  private

  # Return type is T.untyped so specs can stub the HTTP boundary with a plain
  # double — sorbet-runtime rejects RSpec doubles against a concrete type.
  sig { returns(T.untyped) }
  def post_siteverify
    uri = URI.parse(Turnstile::SITEVERIFY_URL)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(form_data)

    Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) { |http| http.request(request) }
  end

  sig { returns(T::Hash[String, String]) }
  def form_data
    data = { "secret" => Turnstile.secret_key, "response" => @token.to_s }
    data["remoteip"] = @remote_ip if @remote_ip.present?
    data
  end

  # Decides the outcome on the response's `success` flag. An unparseable body
  # raises JSON::ParserError, which propagates to #verify's outer rescue and
  # fails open there — no separate rescue needed here.
  sig { params(body: String).returns(T::Boolean) }
  def parse_success(body)
    JSON.parse(body).fetch("success", false) == true
  end
end
