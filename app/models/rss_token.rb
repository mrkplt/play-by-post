# typed: true

class RssToken < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game, optional: true

  validates :token, presence: true, uniqueness: true
  # A user may hold at most one account-level token (game_id nil) and one token
  # per game. Rails builds `WHERE game_id IS NULL` for the nil scope, so this
  # rejects a second account-level token — which the DB composite index cannot
  # (SQLite treats NULLs as distinct). This validation is authoritative.
  validates :user_id, uniqueness: { scope: :game_id }

  before_validation :generate_token, on: :create

  scope :account_level, -> { where(game_id: nil) }

  sig { params(user: User, game: T.nilable(Game)).returns(ActiveRecord::Relation) }
  def self.for_user_scope(user, game)
    where(user_id: user.id, game_id: game&.id)
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
