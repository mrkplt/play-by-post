# typed: true

class Post < ApplicationRecord
  extend T::Sig
  include Draftable::Model

  belongs_to :scene
  belongs_to :user
  has_one :game, through: :scene

  has_one_attached :image

  IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes

  # Drafting scopes and presence-unless-draft, declared here so the wiring is
  # visible; Draftable::Model supplies the shared draft?/published?/publish!
  # behaviour.
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  validates :content, presence: true, unless: :draft?

  # Post-specific and deliberately not shared — a participant may hold at most
  # one draft per scene. Post is the only adopter with a per-user draft, so this
  # uniqueness rule does not generalize.
  validates :user_id, uniqueness: { scope: :scene_id, message: "already has a draft for this scene" }, if: :draft?
  validate :acceptable_image
  validate :images_allowed_for_game

  def display_image
    image.variant(resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85)
  end

  sig { params(user: User).returns(T::Boolean) }
  def editable_by?(user)
    return false unless authored_by?(user)

    within_edit_window?
  end

  sig { params(user: User).returns(T::Boolean) }
  def authored_by?(user)
    self.user == user
  end

  sig { returns(T::Boolean) }
  def within_edit_window?
    window = T.must(game).edit_window_duration
    return true if window.nil?

    created_at > window.ago
  end

  private

  def acceptable_image
    return unless image.attached?

    blob = image.blob
    errors.add(:image, "must be less than 10MB") unless blob.byte_size <= IMAGE_MAX_SIZE

    unless IMAGE_TYPES.include?(blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, GIF, or WebP image")
    end
  end

  def images_allowed_for_game
    return unless image.attached?
    return unless scene&.game&.images_disabled?

    errors.add(:image, "attachments are disabled for this game")
  end
end
