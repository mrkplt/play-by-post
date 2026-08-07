# typed: true

require "net/http"
require "json"

# Creates Fizzy cards for user feedback/recommendations.
#
# The Send Feedback modal collects suggestions into the `feedback` table; this
# service pushes one entry to the personal Fizzy board as a card. Cards created
# through the API are untriaged, so they land in Fizzy's "Maybe?" column.
#
# Credentials required (config/credentials/production.yml.enc):
#   fizzy:
#     api_url: "https://fizzy.example.com"
#     access_token: "<personal-access-token>"
#     account_slug: "<account-slug>"
#     board_id: "<board-id>"
module FizzySweepService
  extend T::Sig

  class ConfigurationError < StandardError; end

  # Creates a card for one feedback entry and logs its card URL on success.
  # Raises on a non-success response or missing configuration.
  sig { params(feedback: Feedback).void }
  def self.create_card(feedback)
    config = Rails.application.credentials.fizzy
    validate_config!(config)

    uri = URI.parse(endpoint(config))
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{config.access_token}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = JSON.generate(card: { title: title_for(feedback), description: description_for(feedback) })

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Fizzy card creation failed: #{response.code} #{response.message}"
    end

    Rails.logger.debug("Fizzy card created for feedback ##{feedback.id}: #{response["Location"]}")
  end

  sig { params(config: T.untyped).void }
  def self.validate_config!(config)
    raise ConfigurationError, "fizzy is not configured" if config.blank?
    raise ConfigurationError, "fizzy.api_url is not configured" if config.api_url.blank?
    raise ConfigurationError, "fizzy.access_token is not configured" if config.access_token.blank?
    raise ConfigurationError, "fizzy.account_slug is not configured" if config.account_slug.blank?
    raise ConfigurationError, "fizzy.board_id is not configured" if config.board_id.blank?
  end

  sig { params(config: T.untyped).returns(String) }
  def self.endpoint(config)
    "#{config.api_url}/#{config.account_slug}/boards/#{config.board_id}/cards"
  end

  sig { params(feedback: Feedback).returns(String) }
  def self.title_for(feedback)
    "Feedback ##{feedback.id}"
  end

  sig { params(feedback: Feedback).returns(String) }
  def self.description_for(feedback)
    lines = [ feedback.body ]
    lines << "Submitted from: #{feedback.url}" if feedback.url.present?

    user = feedback.user
    if user
      name = user.display_name.presence || user.email
      lines << "Submitted by: #{name}"
    end

    lines.join("\n\n")
  end

  private_class_method :validate_config!, :endpoint, :title_for, :description_for
end
