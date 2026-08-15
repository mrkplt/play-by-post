# typed: strict

# A bearer credential for the machine-auth surface (DataApplicationController).
# Scoped per user, per game, per purpose (`scope`): the RSS feed is the first
# consumer (`scope: "rss"`); the API will add its own scope later. The token is
# the sole input a data endpoint receives — it identifies the user and the game,
# and authorization (active membership) is re-checked on every request.
class ApiToken < ApplicationRecord
  extend T::Sig

  # Recognised token purposes. "rss" is the campaign-log feed; "api" is reserved
  # for the forthcoming data API.
  SCOPES = T.let(%w[rss api].freeze, T::Array[String])

  belongs_to :user
  belongs_to :game

  validates :scope, presence: true, inclusion: { in: SCOPES }
  validates :token, presence: true, uniqueness: true
  validates :user_id, uniqueness: { scope: %i[scope game_id] }

  before_validation :generate_token, on: :create

  sig { void }
  def regenerate!
    update!(token: self.class.generate_secure_token)
  end

  sig { returns(String) }
  def self.generate_secure_token
    SecureRandom.hex(32)
  end

  # Finds this user's existing token for the game/scope pair and rotates it,
  # or mints a fresh one — the single "issue me a usable token" operation
  # Profiles::ApiTokensController#create needs, so the controller does not
  # have to know the find-or-regenerate-or-create shape itself.
  sig { params(user: User, game: Game, scope: String).returns(ApiToken) }
  def self.issue_for!(user:, game:, scope:)
    token = user.api_tokens.find_or_initialize_by(game: game, scope: scope)
    token.persisted? ? token.regenerate! : token.save!
    token
  end

  private

  sig { void }
  def generate_token
    self.token = self.class.generate_secure_token if token.blank?
  end
end
