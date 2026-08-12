# typed: strict

require "net/http"

# Verifies a Cloudflare Turnstile token against the siteverify API.
#
# Fails OPEN (returns true) on any outage — unreachable, timeout, unparseable —
# because rack-attack is the abuse backstop; a Cloudflare outage must not block
# logins. Fails CLOSED only on a blank token or an explicit `success: false`.
class TurnstileVerifier
  extend T::Sig

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
    return false if @token.blank?

    response = post_siteverify
    parse_success(response.body)
  rescue StandardError => e
    Rails.logger.warn("Turnstile siteverify unreachable, failing open: #{e.class}: #{e.message}")
    true
  end

  private

  # T.untyped so specs can stub with a plain double (sorbet-runtime rejects
  # doubles against a concrete return type).
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

  # An unparseable body raises and is caught by #verify's fail-open rescue.
  sig { params(body: String).returns(T::Boolean) }
  def parse_success(body)
    JSON.parse(body).fetch("success", false) == true
  end
end
