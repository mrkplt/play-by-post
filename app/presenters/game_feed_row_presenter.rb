# typed: strict

# View model for one game's row in the profile's RSS Feeds section: the game
# name, and — when the viewer already holds an RSS token for it — the
# copyable feed URL and revoke route; otherwise the create-feed route.
# Replaces Shared::RssFeedsSectionComponent::Row, a T::Struct whose `token`
# member exposed a raw ApiToken to the component.
class GameFeedRowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(T::Boolean) }
  def token?
    !@options[:token].nil?
  end

  sig { returns(String) }
  def feed_url
    @options.fetch(:urls).rss_feed_url(token: @options[:token].token)
  end

  # The value the shared token section reveals for this row — for RSS, the whole
  # feed URL (the token is embedded in it).
  sig { returns(String) }
  def secret_value
    feed_url
  end

  sig { returns(String) }
  def revoke_path
    @options.fetch(:urls).profile_api_token_path(@options[:token])
  end

  sig { returns(String) }
  def create_path
    @options.fetch(:urls).profile_api_tokens_path
  end

  sig { returns(Integer) }
  def game_id
    @model.id
  end
end
