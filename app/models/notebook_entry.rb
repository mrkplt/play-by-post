# typed: true

# A game-level scratchpad card: a title and a markdown body, moved through a
# small kanban (new -> expand -> done -> discard) by the GM, and optionally
# "promoted" into a full Page. Addressed by a globally unique, non-editable
# 16-char alphanumeric slug (games/:game_id/notebook_entries/:slug). GM-only in
# every direction — unlike Page, no other member can view or write entries.
#
# MAINTENANCE: notebook entries belong to a game, so GamePurgeJob#delete_records
# deletes them explicitly on purge (there is no attachment, so #purge_artifacts
# is unaffected). See Game's association comment and REQUIREMENTS "Game Deletion".
class NotebookEntry < ApplicationRecord
  extend T::Sig
  include Versionable::Model

  SLUG_LENGTH = 16

  STATUSES = %w[new expand done discard].freeze

  belongs_to :game
  belongs_to :promoted_page, class_name: "Page", optional: true,
             inverse_of: :promoted_from_entries
  has_many :notebook_entry_versions, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  # The slug is assigned once on create and never editable thereafter, so the
  # entry's URL is stable for the life of the entry.
  before_validation :generate_slug, on: :create

  # Route helpers address an entry by its slug, not its numeric id.
  sig { returns(T.nilable(String)) }
  def to_param
    slug
  end

  sig { returns(String) }
  def self.generate_secure_slug
    SecureRandom.alphanumeric(SLUG_LENGTH)
  end

  sig { returns(T::Boolean) }
  def promoted?
    promoted_page_id.present?
  end

  # The versions association Versionable::Model snapshots through — an entry's
  # change history lives in notebook_entry_versions.
  sig { override.returns(T.untyped) }
  def versions
    notebook_entry_versions
  end

  # A notebook entry version captures only the editable prose fields — title and
  # body. Status and promotion are not versioned. Attribution is the acting
  # user; every save happens in a request where Current.user is set.
  sig { override.returns(T::Hash[Symbol, T.untyped]) }
  def version_attributes
    {
      title: title,
      body: body,
      edited_by_id: Current.user&.id
    }
  end

  private

  sig { void }
  def generate_slug
    self.slug = self.class.generate_secure_slug if slug.blank?
  end
end
