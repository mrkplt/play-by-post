# typed: true

class Scene < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :parent_scene, class_name: "Scene", optional: true

  has_many :child_scenes, class_name: "Scene", foreign_key: :parent_scene_id, dependent: :nullify, inverse_of: :parent_scene
  has_many :scene_participants, dependent: :destroy
  has_many :users, through: :scene_participants
  has_many :posts, dependent: :destroy
  has_one :scene_summary, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }

  scope :active, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :visible_to, ->(user, game) {
    gm = game.game_master?(user)
    gm ? all : where(private: false).or(where(id: joins(:scene_participants).where(scene_participants: { user_id: user.id })))
  }

  sig { returns(T::Boolean) }
  def resolved?
    resolved_at.present?
  end

  sig { returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def last_activity_at
    if posts.loaded?
      posts.map(&:created_at).max || created_at
    else
      posts.maximum(:created_at) || created_at
    end
  end

  sig { params(user: User).returns(T::Boolean) }
  def participant?(user)
    scene_participants.exists?(user: user)
  end

  # Fill a blank title before validation, in-band and visible here rather than
  # behind a before_validation callback (bin/check-callbacks). Unlike the slug
  # generators this runs on every validation, not only create, matching the
  # original callback which had no `on:` restriction — a title blanked on update
  # is re-defaulted.
  sig { params(context: T.untyped).returns(T::Boolean) }
  def valid?(context = nil)
    default_title
    super
  end

  private

  def default_title
    self.title = Time.current.strftime("%b %-d, %Y %-I:%M %p") if title.blank?
  end
end
