# typed: strict

class Shared::RssTokenComponent < ApplicationComponent
  extend T::Sig

  sig { params(rss_token: T.nilable(RssToken)).void }
  def initialize(rss_token:)
    @rss_token = T.let(rss_token, T.nilable(RssToken))
  end

  sig { returns(T::Boolean) }
  def token_present?
    @rss_token.present?
  end

  sig { returns(T.nilable(String)) }
  def token_value
    @rss_token&.token
  end

  sig { returns(String) }
  def generate_path
    T.unsafe(helpers).generate_rss_token_profile_path
  end

  sig { returns(String) }
  def revoke_path
    T.unsafe(helpers).revoke_rss_token_profile_path
  end
end
