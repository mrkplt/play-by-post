# typed: true

class Post < ApplicationRecord
  extend T::Sig
  include Draftable::Model

  belongs_to :scene
  belongs_to :user
  has_one :game, through: :scene

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
end
