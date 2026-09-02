# typed: true

class SceneSummary < ApplicationRecord
  extend T::Sig
  include Draftable::Model
  include AiGenerated::Model
  include Versionable::Model

  belongs_to :scene
  belongs_to :edited_by, class_name: "User", optional: true
  has_many :scene_summary_versions, dependent: :destroy

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
  # RSS feed can never diverge on what "hidden" excludes. This gates viewing;
  # generation is gated by the GM's game-level Game#ai_summaries_enabled.
  # ai_generated?/edited?/apply_manual_edit now come from AiGenerated::Model.
  sig { params(relation: T.untyped, user: User).returns(T.untyped) }
  def self.visible_to(relation, user)
    return relation unless user.user_profile&.hidden?

    relation.where(generated_at: nil)
  end

  # Whether this one summary is visible to a specific viewer — the per-record
  # counterpart of .visible_to, folding in the draft rule. A draft is visible
  # only to a manager (its author); an AI-generated summary is hidden from a
  # viewer whose ai_display_preference is "hidden". The single source of the
  # scene view's visibility: SceneShowBuilder gates the summary block with it.
  #
  # Expressed through SceneSummaryVisibility so the "show on the page" decision
  # and the "broadcast to this stream" decision (SceneSummaryJob) share one
  # mapping: a viewer sees the summary exactly when their visibility class is one
  # this summary is broadcast to. Manager-ness is read from the game (the same
  # GM check SceneSummaryPolicy#manage? makes), so no policy needs threading in.
  sig { params(viewer: User).returns(T::Boolean) }
  def visible_to?(viewer)
    SceneSummaryVisibility.classes_for(self)
      .include?(SceneSummaryVisibility.for_viewer(game: T.must(T.must(scene).game), viewer: viewer))
  end

  # The AI-generated flag is sticky (Fizzy #122), cleared only when the body is
  # emptied. Enforced at the save boundary so it holds for every write path — the
  # draft autosave (a raw #update), publish, and #apply_manual_edit alike — not
  # just the hand-edit action. Runs before super so the version snapshot
  # Versionable::Model takes records the reset generated_at. save/save! both
  # route here for the same reason Versionable overrides both.
  sig { params(options: T.untyped).returns(T.untyped) }
  def save(**options)
    reset_provenance_if_blank
    super
  end

  sig { params(options: T.untyped).returns(T.untyped) }
  def save!(**options)
    reset_provenance_if_blank
    super
  end

  # The versions association Versionable::Model snapshots through — a summary's
  # change history lives in scene_summary_versions.
  sig { override.returns(T.untyped) }
  def versions
    scene_summary_versions
  end

  # A summary version captures the body and, uniquely among adopters, its
  # AI-provenance (generated_at) — so "was this revision AI-authored" is a
  # per-revision historical fact. Attribution prefers the request's Current.user;
  # it falls back to the record's own edited_by, which #apply_manual_edit sets
  # from the editor it was handed — so a direct model call (no Current.user) still
  # attributes the version to the right person. (The generation job upserts and so
  # bypasses this method, writing its own version attributed to the requester.)
  sig { override.returns(T::Hash[Symbol, T.untyped]) }
  def version_attributes
    {
      body: body,
      generated_at: generated_at,
      edited_by_id: Current.user&.id || edited_by_id
    }
  end

  private

  # Clears the AI-generated provenance when the body has been emptied — the
  # "unless all text was deleted" half of the sticky rule. Whitespace-only
  # counts as empty.
  sig { void }
  def reset_provenance_if_blank
    self.generated_at = nil if body.blank?
  end
end
