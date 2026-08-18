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
    it "flips the flag for the GM and returns to the game" do
      sign_in gm

      patch toggle_sheets_hidden_game_path(game)

      expect(game.reload.sheets_hidden?).to be(true)
      expect(response).to redirect_to(game_path(game))
    end

    it "denies a player" do
      sign_in player

      patch toggle_sheets_hidden_game_path(game)

      expect(game.reload.sheets_hidden?).to be(false)
    end
  end

  describe "PATCH /games/:id/toggle_ai_summaries_enabled" do
    it "flips the flag and returns to player management" do
      sign_in gm

      patch toggle_ai_summaries_enabled_game_path(game)

      expect(game.reload.ai_summaries_enabled?).to be(true)
      expect(response).to redirect_to(game_player_management_path(game))
    end
  end
end
