# typed: true

# A per-game markdown template that seeds new content of a given type. When a
# template exists for (game, content_type), a new record of that type starts
# pre-filled with the template body. One template per game per type.
#
# Deliberately its own model rather than a flag on the content rows: a template
# is configuration, not content, so it stays orthogonal to Draftable and
# Versionable — it never lists, versions, or drafts.
class ContentTemplate < ApplicationRecord
  extend T::Sig

  # The content types a template can seed. Each maps to a model whose new-record
  # form pre-fills its markdown field from the template body.
  CONTENT_TYPES = %w[page note character].freeze

  belongs_to :game

  validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }
  validates :content_type, uniqueness: { scope: :game_id }
  validates :body, presence: true

  # The template body a new record of this type should start with, or nil when
  # the game has no template for that type. Used by the new-record forms to
  # pre-fill their markdown field.
  sig { params(game: Game, content_type: String).returns(T.nilable(String)) }
  def self.body_for(game:, content_type:)
    where(game: game, content_type: content_type).pick(:body)
  end
end
