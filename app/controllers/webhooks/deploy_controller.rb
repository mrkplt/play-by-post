# typed: true

module Webhooks
  # Receives a deploy webhook from GitHub Actions after a production image is
  # built and pushed to GHCR, and forwards a deploy trigger to Coolify.
  #
  # Coolify runs on the internal network and is not exposed to the internet,
  # so GitHub cannot call it directly. This endpoint is internet-facing (it
  # serves the site) and can reach Coolify internally, so it acts as a relay.
  #
  # Authentication is a shared bearer secret compared in constant time. The
  # actual outbound call to Coolify is handed to +CoolifyDeployJob+ so the
  # response to GitHub is immediate and the forward can be retried.
  #
  # Credentials required:
  #   deploy_webhook_secret: "<random-shared-secret>"  # also a GitHub Actions secret
  #   coolify:
  #     deploy_url: "http://<internal-host>:8000/api/v1/deploy?uuid=<app-uuid>"
  #     token: "<coolify-api-token>"
  #
  # Register this URL in the GitHub Actions workflow as the deploy relay:
  #   https://<your-host>/webhooks/deploy
  class DeployController < ActionController::Base
    extend T::Sig

    skip_forgery_protection

    before_action :verify_secret

    sig { void }
    def create
      CoolifyDeployJob.perform_later
      head :accepted
    end

    private

    sig { void }
    def verify_secret
      provided = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
      expected = Rails.application.credentials.deploy_webhook_secret.to_s

      return if expected.present? &&
                ActiveSupport::SecurityUtils.secure_compare(provided, expected)

      Rails.logger.warn("Deploy webhook verification failed")
      head :unauthorized
    end
  end
end
