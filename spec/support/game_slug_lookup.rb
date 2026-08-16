# Shared example locking in that a controller resolves the game from its URL
# slug (Game.find_by!(slug:)) — never the raw numeric id. Each including
# controller supplies a signed-in user and a `perform_request` that issues the
# real HTTP call for a given game id. Both cases 404 through the not_found
# handler (redirect home with "That could not be found."):
#   - an unknown slug, and
#   - the game's own numeric id (proving the action is slug-addressed, not
#     id-addressed).
# The valid-slug happy path is already covered by each controller's own specs.
#
# Usage:
#   it_behaves_like "a slug-addressed game action" do
#     let(:signed_in_user) { gm }
#     def perform_request(game_id) = get game_game_links_path(game_id)
#   end
RSpec.shared_examples "a slug-addressed game action" do
  before { sign_in(signed_in_user) }

  it "404s (redirects home) when the slug matches no game" do
    perform_request("no-such-game-slug")
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("That could not be found.")
  end

  it "does not resolve a game by its numeric id" do
    perform_request(game.id.to_s)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("That could not be found.")
  end
end
