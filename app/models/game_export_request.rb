# typed: true

class GameExportRequest < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game, optional: true

  has_one_attached :archive

  # How long a successful export "receipt" stays valid. Within this window a new
  # request resends the existing export instead of processing a fresh one; after
  # it, a request processes again.
  RECEIPT_WINDOW = T.let(24.hours, ActiveSupport::Duration)

  # The most recent valid receipt for a game: a request that succeeded within the
  # window and whose archive is still attached. It is the source of truth for
  # whether to resend vs. process, and for the "last export" display.
  sig { params(user: User, game: T.nilable(Game)).returns(T.nilable(GameExportRequest)) }
  def self.valid_receipt_for(user, game)
    where(user: user, game: game)
      .where(succeeded_at: RECEIPT_WINDOW.ago..)
      .order(succeeded_at: :desc)
      .find { |request| request.archive.attached? }
  end

  sig { returns(T::Boolean) }
  def receipt?
    succeeded_at.present? && archive.attached?
  end

  sig { void }
  def mark_succeeded!
    update!(succeeded_at: Time.current)
  end
end
