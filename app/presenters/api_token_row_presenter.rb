# typed: strict

# View model for one game's row in the profile's "API tokens" section: the game
# name, and — when the viewer already holds an api-scoped token for it — the
# copyable raw token value and revoke route; otherwise the create route.
# Parallels GameFeedRowPresenter, but the populated state exposes the raw token
# value for Ui::SecretFieldComponent rather than a feed URL.
class ApiTokenRowPresenter < BasePresenter
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
  def token_value
    @options[:token].token
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
