# typed: true

class SceneSummary < ApplicationRecord
  extend T::Sig

  belongs_to :scene
  belongs_to :edited_by, class_name: "User", optional: true

  validates :body, presence: true

  # The public campaign-log listing for a game: summaries of its public, resolved
  # scenes, newest first. Shared by the members-only HTML index and the RSS feed
  # so the two never diverge.
  sig { params(game: Game).returns(ActiveRecord::Relation) }
  def self.public_for_game(game)
    joins(scene: :game)
      .where(scenes: { game_id: game.id, private: false })
      .where.not(scenes: { resolved_at: nil })
      .includes(:scene)
      .order("scenes.resolved_at DESC")
  end

  sig { returns(T::Boolean) }
  def ai_generated?
    generated_at.present?
  end

  sig { returns(T::Boolean) }
  def edited?
    edited_at.present?
  end
end
