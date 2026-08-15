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
    location = post_card(title: title_for(feedback), description: description_for(feedback))
    Rails.logger.debug("Fizzy card created for feedback ##{feedback.id}: #{location}")
  end

  # The card fields and Fizzy credentials needed to build the request, grouped
  # so #build_card_request and #send_card_request take one object instead of
  # threading config/title/description through separately.
  CardRequest = Data.define(:config, :title, :description)

  # POSTs a single card to the board. Cards created through the API are
  # untriaged, so they land in Fizzy's "Maybe?" column. Returns the Location
  # header (the new card's URL); raises on a non-success response or missing
  # configuration.
  sig { params(title: String, description: String).returns(T.nilable(String)) }
  def self.post_card(title:, description:)
    config = Rails.application.credentials.fizzy
    validate_config!(config)

    response = send_card_request(CardRequest.new(config: config, title: title, description: description))
    validate_response!(response)
    response["Location"]
  end

  sig { params(card_request: FizzySweepService::CardRequest).returns(T.untyped) }
  def self.send_card_request(card_request)
    uri = URI.parse(endpoint(card_request.config))
    request = build_card_request(uri, card_request)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end

  sig { params(uri: URI::Generic, card_request: FizzySweepService::CardRequest).returns(Net::HTTP::Post) }
  def self.build_card_request(uri, card_request)
    Net::HTTP::Post.new(uri).tap do |request|
      request["Authorization"] = "Bearer #{card_request.config.access_token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = JSON.generate(card: { title: card_request.title, description: card_request.description })
    end
  end

  sig { params(response: T.untyped).void }
  def self.validate_response!(response)
    return if response.is_a?(Net::HTTPSuccess)

    raise "Fizzy card creation failed: #{response.code} #{response.message}"
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
    url = feedback.url
    user = feedback.user

    [
      feedback.body,
      (url.present? ? "Submitted from: #{url}" : nil),
      (user ? "Submitted by: #{user.email}" : nil)
    ].compact.join("\n\n")
  end

  private_class_method :send_card_request, :build_card_request, :validate_response!,
                        :validate_config!, :endpoint, :title_for, :description_for
end
