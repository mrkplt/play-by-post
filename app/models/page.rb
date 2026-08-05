# typed: true

# A game-level wiki page: a title and a markdown body, addressed by a globally
# unique, non-editable 16-char alphanumeric slug (games/:game_id/pages/:slug).
# Created and edited by the GM; visible to every non-banned member of the game.
#
# MAINTENANCE: pages belong to a game, so GamePurgeJob#delete_records deletes
# them explicitly on purge (there is no attachment, so #purge_artifacts is
# unaffected). See Game's association comment and REQUIREMENTS "Game Deletion".
class Page < ApplicationRecord
  extend T::Sig

  SLUG_LENGTH = 16

  belongs_to :game

  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true

  # The slug is assigned once on create and never editable thereafter, so the
  # page's URL is stable for the life of the page.
  before_validation :generate_slug, on: :create

  # Route helpers address a page by its slug, not its numeric id.
  sig { returns(T.nilable(String)) }
  def to_param
    slug
  end

  sig { returns(String) }
  def self.generate_secure_slug
    SecureRandom.alphanumeric(SLUG_LENGTH)
  end

  private

  sig { void }
  def generate_slug
    self.slug = self.class.generate_secure_slug if slug.blank?
  end
end
