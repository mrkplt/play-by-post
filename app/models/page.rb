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
  include Draftable::Model
  include Versionable::Model

  SLUG_LENGTH = 16

  belongs_to :game
  has_many :page_versions, dependent: :destroy

  # A notebook entry may be "promoted" into a Page, recording the resulting
  # page id on the entry. Deleting the page must NOT delete the entry — it
  # un-promotes it (nullifies the reference), so the entry survives as an
  # ordinary card. Without this, SQLite's FK on notebook_entries.promoted_page_id
  # raises on destroy (GlitchTip WEBAPP-5). GamePurgeJob deletes both tables
  # wholesale, so the purge path is unaffected.
  has_many :promoted_from_entries, class_name: "NotebookEntry",
           foreign_key: :promoted_page_id, dependent: :nullify,
           inverse_of: :promoted_page

  # Drafting scopes and presence-unless-draft, declared here so the wiring is
  # visible; Draftable::Model supplies the shared draft?/published?/publish!
  # behaviour. A draft may hold a blank title; a published page must have one.
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  # /api index filters. Each no-ops on a nil argument (a Rails scope that returns
  # nil yields `all`), so the /api filter chain narrows only by the params a
  # client supplied. `title_matching` is a case-insensitive substring search;
  # SQLite's LIKE is case-insensitive for ASCII, and the term is bound (not
  # interpolated) so LIKE metacharacters in it are escaped. `created_by` returns
  # the pages a user *created* — the editor of the page's earliest version row,
  # which never changes as later versions accrue — so a later editor of someone
  # else's page is not matched. `edited_by` returns pages the user authored *any*
  # version of, creator or not. `created_after` floors on created_at.
  scope :title_matching, ->(term) { where("title LIKE ?", "%#{sanitize_sql_like(term)}%") if term }
  scope :created_by, ->(user_id) {
    if user_id
      where(id: PageVersion.where(edited_by_id: user_id).where(
        "page_versions.created_at = (SELECT MIN(created_at) FROM page_versions v WHERE v.page_id = page_versions.page_id)"
      ).select(:page_id))
    end
  }
  scope :edited_by, ->(user_id) {
    where(id: PageVersion.where(edited_by_id: user_id).select(:page_id)) if user_id
  }
  scope :created_after, ->(time) { where("created_at >= ?", time) if time }

  validates :title, presence: true, unless: :draft?
  validates :title, length: { maximum: 200 }
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

  # The versions association Versionable::Model snapshots through — a page's
  # change history lives in page_versions.
  sig { override.returns(T.untyped) }
  def versions
    page_versions
  end

  # A page version captures both editable fields. Attribution is the acting
  # user; a page has no owning user to fall back to, and every save happens in a
  # request where Current.user is set.
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
