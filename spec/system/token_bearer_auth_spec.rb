require "rails_helper"

# End-to-end guard for the TokenBearerAuthentication invariant: a per-request
# bearer token (here, the RSS feed's ?token=) authorizes that one request and
# NEVER establishes a session. Without this, a brute-forced token could be traded
# for an in-app session and used to impersonate the owner. As more token-based
# per-request endpoints land, they include TokenBearerAuthentication and this
# spec is the regression net for the whole class of endpoint.
RSpec.describe "Token-bearer feed authentication", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game, name: "Barovia Nights") }

  before { create(:game_member, game: game, user: user) }

  it "serves the feed for a valid token but grants no in-app session" do
    scene = create(:scene, :resolved, game: game)
    create(:scene_summary, scene: scene, body: "The mists part over Barovia.")
    token = create(:rss_token, user: user, game: game)

    # A real browser fetch of the token-bearing feed succeeds…
    visit feeds_path(token: token.token)
    expect(page).to have_content("The mists part over Barovia.")

    # …but the same browser, now visiting a protected in-app page, is treated as
    # unauthenticated — the feed request created no session for the token owner.
    visit profile_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    expect(page).to have_content("Sign in")
  end

  it "does not leak a session even after a denied (banned) feed request" do
    banned = create(:user, :with_profile)
    create(:game_member, :banned, game: game, user: banned)
    token = create(:rss_token, user: banned, game: game)

    visit feeds_path(token: token.token)

    visit profile_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end
end
