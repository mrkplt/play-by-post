# typed: false

# Server-side sessions (activerecord-session_store): the session payload lives
# in the `sessions` table, not the client cookie. In production that table is in
# the primary SQLite database on the mounted `/data` volume, so a login survives
# deploys and container restarts. The cookie holds only the opaque session id.
#
# `expire_after` bounds how long a session id stays valid; paired with
# `config.remember_for` (30 days) in config/initializers/devise.rb so both the
# session and the remember-me cookie carry a login for a month.
Rails.application.config.session_store :active_record_store,
  key: "_play_by_post_session",
  expire_after: 30.days
