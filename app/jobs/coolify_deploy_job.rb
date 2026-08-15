# typed: true

require "net/http"

# Wraps the raw Net::HTTP response from a Coolify deploy trigger so the
# success/failure decision (and its error message) live with the data they
# describe, rather than reaching into the response from the job.
class CoolifyDeployResponse
  extend T::Sig

  sig { params(http_response: Net::HTTPResponse).void }
  def initialize(http_response)
    @http_response = http_response
  end

  sig { returns(String) }
  def code
    T.must(@http_response.code)
  end

  sig { void }
  def verify_success!
    return if @http_response.is_a?(Net::HTTPSuccess)

    raise "Coolify deploy trigger failed: #{code} #{@http_response.message}"
  end
end

# Forwards a deploy trigger to Coolify over the internal network.
#
# Coolify is not exposed to the internet, so this runs from inside the app
# (which can reach it internally) rather than from GitHub Actions directly.
# Enqueued by +Webhooks::DeployController+ after GitHub reports a fresh image.
#
# Credentials required:
#   coolify:
#     deploy_url: "http://<internal-host>:8000/api/v1/deploy?uuid=<app-uuid>"
#     token: "<coolify-api-token>"
class CoolifyDeployJob < ApplicationJob
  extend T::Sig

  queue_as :default

  # Missing configuration is not retryable, so discard rather than retry.
  class ConfigurationError < StandardError; end

  discard_on ConfigurationError

  sig { void }
  def perform
    url = deploy_url
    token = api_token

    response = trigger_deploy(url, token)
    response.verify_success!

    Rails.logger.debug("Coolify deploy triggered: #{response.code}")
  end

  private

  sig { returns(String) }
  def deploy_url
    url = Rails.application.credentials.coolify&.deploy_url
    raise ConfigurationError, "coolify.deploy_url is not configured" if url.blank?

    url
  end

  sig { returns(String) }
  def api_token
    token = Rails.application.credentials.coolify&.token
    raise ConfigurationError, "coolify.token is not configured" if token.blank?

    token
  end

  sig { params(url: String, token: String).returns(CoolifyDeployResponse) }
  def trigger_deploy(url, token)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"

    CoolifyDeployResponse.new(send_request(uri, request))
  end

  sig { params(uri: URI::Generic, request: Net::HTTP::Post).returns(Net::HTTPResponse) }
  def send_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end
end
