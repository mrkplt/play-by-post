# typed: true

class Character < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :user
  has_many :character_versions, dependent: :destroy

  validates :name, presence: true

  after_save :snapshot_version

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  sig { returns(T::Boolean) }
  def archived?
    archived_at.present?
  end

  sig { void }
  def archive!
    update!(archived_at: Time.current)
  end

  scope :visible_to, ->(viewer, game) {
    return all if game.game_master?(viewer)
    return where(user: viewer) if game.sheets_hidden?

    where(hidden: false).or(where(user: viewer))
  }

  sig { params(user: User, game: Game).returns(T::Boolean) }
  def editable_by?(user, game)
    self.user == user || game.game_master?(user)
  end

  private

  def snapshot_version
    character_versions.create!(
      content: content.to_s,
      edited_by_id: Current.user&.id || user_id
    )
  end
end
