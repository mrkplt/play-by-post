# typed: true

require "net/http"

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
    config = Rails.application.credentials.coolify
    url    = config&.deploy_url
    token  = config&.token

    raise ConfigurationError, "coolify.deploy_url is not configured" if url.blank?
    raise ConfigurationError, "coolify.token is not configured" if token.blank?

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Coolify deploy trigger failed: #{response.code} #{response.message}"
    end

    Rails.logger.debug("Coolify deploy triggered: #{response.code}")
  end
end
