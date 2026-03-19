class Character < ApplicationRecord
  belongs_to :game
  belongs_to :user
  has_many :character_versions, dependent: :destroy

  validates :name, presence: true

  after_save :snapshot_version

  scope :active, -> { where(active: true) }
  scope :visible_to, ->(viewer, game) {
    return all if game.game_master?(viewer)
    return all if game.sheets_hidden == false

    where(hidden: false).or(where(user: viewer))
  }

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
