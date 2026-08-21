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
end
