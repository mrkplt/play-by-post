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

  # A person editing the body by hand supersedes any AI generation — clears
  # generated_at/model_used/token counts so #ai_generated? and the "edited"
  # byline read correctly afterward, alongside the new body and editor.
  sig { params(body: T.nilable(String), editor: User).returns(T::Boolean) }
  def apply_manual_edit(body:, editor:)
    update(body: body, edited_by: editor, edited_at: Time.current,
           generated_at: nil, model_used: nil, input_tokens: nil, output_tokens: nil)
  end
end
