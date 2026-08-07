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

  validates :description, presence: true, length: { maximum: 200 }
  validates :url, presence: true
  validate :http_url

  private

  sig { void }
  def http_url
    return if url.blank?

    parsed = URI.parse(url)
    return if %w[http https].include?(parsed.scheme) && parsed.host.present?

    errors.add(:url, "must be a valid http(s) URL")
  rescue URI::InvalidURIError
    errors.add(:url, "must be a valid http(s) URL")
  end
end
