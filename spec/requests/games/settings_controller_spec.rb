require "rails_helper"

RSpec.describe Games::SettingsController, type: :request do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = patch toggle_sheets_hidden_game_path(game_id)
  end

  describe "PATCH /games/:id/toggle_sheets_hidden" do
    it "flips the flag for the GM and swaps the toggle in place" do
      sign_in gm

      patch toggle_sheets_hidden_game_path(game)

      expect(game.reload.sheets_hidden?).to be(true)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("sheets_toggle")
      expect(response.body).to include("toast_layer")
    end

    it "denies a player" do
      sign_in player

      patch toggle_sheets_hidden_game_path(game)

      expect(game.reload.sheets_hidden?).to be(false)
    end
  end

  describe "PATCH /games/:id/toggle_ai_summaries_enabled" do
    it "flips the flag and swaps the toggle in place" do
      sign_in gm

      patch toggle_ai_summaries_enabled_game_path(game)

      expect(game.reload.ai_summaries_enabled?).to be(true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ai_summaries_toggle")
      expect(response.body).to include("toast_layer")
    end

    it "renders the card presentation when no presentation param is given (Edit Game)" do
      sign_in gm

      patch toggle_ai_summaries_enabled_game_path(game)

      expect(response.body).to include("A summary is generated automatically each time a scene resolves.")
    end

    it "renders the row presentation when presentation=row (Player Management), targeting the same wrapper id" do
      sign_in gm

      patch toggle_ai_summaries_enabled_game_path(game), params: { presentation: "row" }

      expect(response.body).to include("ai_summaries_toggle")
      expect(response.body).to include("role=\"switch\"")
      expect(response.body).not_to include("A summary is generated automatically each time a scene resolves.")
    end
  end

  describe "PATCH /games/:id/toggle_player_contributions_enabled" do
    it "flips the flag for the GM and swaps the toggle in place" do
      sign_in gm

      patch toggle_player_contributions_enabled_game_path(game)

      expect(game.reload.player_contributions_enabled?).to be(true)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("player_contributions_toggle")
      expect(response.body).to include("toast_layer")
    end

    it "denies a player" do
      sign_in player

      patch toggle_player_contributions_enabled_game_path(game)

      expect(game.reload.player_contributions_enabled?).to be(false)
    end
  end
end
