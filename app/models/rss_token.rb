# typed: true

class RssToken < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game

  validates :token, presence: true, uniqueness: true
  # A user holds at most one token per game.
  validates :user_id, uniqueness: { scope: :game_id }

  before_validation :generate_token, on: :create

  sig { params(user: User, game: Game).returns(ActiveRecord::Relation) }
  def self.for_user_scope(user, game)
    where(user_id: user.id, game_id: game.id)
  end

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
