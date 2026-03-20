class Scene < ApplicationRecord
  belongs_to :game
  belongs_to :parent_scene, class_name: "Scene", optional: true

  has_one_attached :image
  has_many :child_scenes, class_name: "Scene", foreign_key: :parent_scene_id, dependent: :nullify
  has_many :scene_participants, dependent: :destroy
  has_many :users, through: :scene_participants
  has_many :posts, dependent: :destroy

  before_validation :default_title

  validates :title, presence: true, length: { maximum: 200 }

  scope :active, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :visible_to, ->(user, game) {
    gm = game.game_master?(user)
    gm ? all : where(private: false).or(where(id: joins(:scene_participants).where(scene_participants: { user_id: user.id })))
  }

  def resolved?
    resolved_at.present?
  end

  def last_activity_at
    if posts.loaded?
      posts.map(&:created_at).max || created_at
    else
      posts.maximum(:created_at) || created_at
    end
  end

  def participant?(user)
    scene_participants.exists?(user: user)
  end

  private

  def default_title
    self.title = Time.current.strftime("%b %-d, %Y %-I:%M %p") if title.blank?
  end
end
