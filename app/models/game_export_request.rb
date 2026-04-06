# typed: true

class GameExportRequest < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game, optional: true

  has_one_attached :archive

  RATE_LIMIT_WINDOW = T.let(24.hours, ActiveSupport::Duration)

  sig { params(user: User, game: T.nilable(Game)).returns(T::Boolean) }
  def self.rate_limited?(user, game)
    where(user: user, game: game)
      .where(created_at: RATE_LIMIT_WINDOW.ago..)
      .exists?
  end

  sig { params(user: User, game: T.nilable(Game)).returns(T.nilable(GameExportRequest)) }
  def self.most_recent_for(user, game)
    where(user: user, game: game)
      .where(created_at: RATE_LIMIT_WINDOW.ago..)
      .order(created_at: :desc)
      .first
  end
end
