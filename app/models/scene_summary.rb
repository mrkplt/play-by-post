# typed: true

class SceneSummary < ApplicationRecord
  extend T::Sig
  include Draftable::Model
  include AiGenerated::Model

  belongs_to :scene
  belongs_to :edited_by, class_name: "User", optional: true
  belongs_to :generated_by, class_name: "User", optional: true

  # Drafting scopes and presence-unless-draft, declared here so the wiring is
  # visible; Draftable::Model supplies the shared draft?/published?/publish!
  # behaviour. A draft summary may hold a blank body; a published one must not.
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  validates :body, presence: true, unless: :draft?

  # The public campaign-log listing for a game: published summaries of its
  # public, resolved scenes, newest first. Shared by the members-only HTML index
  # and the RSS feed so the two never diverge. Excludes drafts — an in-progress
  # summary is invisible to readers until its author publishes it.
  sig { params(game: Game).returns(ActiveRecord::Relation) }
  def self.public_for_game(game)
    published
      .joins(scene: :game)
      .where(scenes: { game_id: game.id, private: false })
      .where.not(scenes: { resolved_at: nil })
      .includes(:scene)
      .order("scenes.resolved_at DESC")
  end

  # The AI Control Plane's per-viewer DISPLAY filter: a user whose
  # ai_display_preference is "hidden" does not see AI-generated summaries at
  # all — composed with .public_for_game (or any other relation) rather than
  # duplicated at each call site, so the HTML index, the scene view, and the
  # RSS feed can never diverge on what "hidden" excludes. Independent of
  # ai_summaries_consent (producing, gates generation) — this gates viewing.
  # ai_generated?/edited?/apply_manual_edit now come from AiGenerated::Model.
  sig { params(relation: T.untyped, user: User).returns(T.untyped) }
  def self.visible_to(relation, user)
    return relation unless user.user_profile&.hidden?

    relation.where(generated_at: nil)
  end
end
