# typed: true

# A GM-curated external link for a game: a short description (what the link is)
# and the URL it points at. Links leave the site, so they are always rendered
# in a new tab with rel="noopener noreferrer" behind a red off-site warning, and
# the URL is validated to be an absolute http(s) URL so a link can never point
# at a javascript: or other scheme.
#
# MAINTENANCE: game_links belong to a game, so GamePurgeJob#delete_records
# deletes them explicitly on purge (there is no attachment, so
# #purge_artifacts is unaffected). See Game's association comment and
# REQUIREMENTS "Game Deletion".
class GameLink < ApplicationRecord
  extend T::Sig

  belongs_to :game
  # The member who created this link. Nullable for links that predate player
  # contributions (Fizzy #18) — those were backfilled to the game's GM, so a
  # live null only occurs transiently before save.
  belongs_to :created_by, class_name: "User", optional: true

  validates :description, presence: true, length: { maximum: 200 }
  validates :url, presence: true
  validate :http_url

  # Whether `user` authored this link — the "delete your own contribution" gate
  # (Fizzy #18). A nil creator (should not occur post-backfill) never equals a
  # real user's id, so no separate nil guard is needed.
  sig { params(user: User).returns(T::Boolean) }
  def created_by?(user)
    created_by_id == user.id
  end

  private

  sig { void }
  def http_url
    return if url.blank?
    return if valid_http_url?

    errors.add(:url, "must be a valid http(s) URL")
  end

  sig { returns(T::Boolean) }
  def valid_http_url?
    %w[http https].include?(url_scheme) && url_host.present?
  rescue URI::InvalidURIError
    false
  end

  sig { returns(T.nilable(String)) }
  def url_scheme
    URI.parse(url).scheme
  end

  sig { returns(T.nilable(String)) }
  def url_host
    URI.parse(url).host
  end
end
