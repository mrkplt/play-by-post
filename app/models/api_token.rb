# typed: strict

# A bearer credential for the machine-auth surface (DataApplicationController).
# Scoped per user, per game, per purpose (`scope`): the RSS feed is the first
# consumer (`scope: "rss"`); the API will add its own scope later. The token is
# the sole input a data endpoint receives — it identifies the user and the game,
# and authorization (active membership) is re-checked on every request.
class ApiToken < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game

  validates :scope, presence: true
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

  private

  sig { void }
  def generate_token
    self.token = self.class.generate_secure_token if token.blank?
  end
end
