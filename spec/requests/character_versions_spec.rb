require "rails_helper"

RSpec.describe CharacterVersionsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game, user: player) }
  let(:version) { character.character_versions.create!(content: "v1", edited_by: player) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:game_id/characters/:character_id/versions/:id" do
    it "GM can view a character version" do
      sign_in(gm)
      get game_character_character_version_path(game, character, version)
      expect(response).to have_http_status(:ok)
    end

    it "active player can view a character version" do
      sign_in(player)
      get game_character_character_version_path(game, character, version)
      expect(response).to have_http_status(:ok)
    end

    it "shows editor email when editor has no display name" do
      nameless = create(:user)
      create(:game_member, game: game, user: nameless)
      anon_version = character.character_versions.create!(content: "v2", edited_by: nameless)
      sign_in(player)
      get game_character_character_version_path(game, character, anon_version)
      expect(response.body).to include(nameless.email.split("@").first)
    end

    it "outsider is redirected to root" do
      sign_in(outsider)
      get game_character_character_version_path(game, character, version)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
    end

    it "unauthenticated user is redirected" do
      get game_character_character_version_path(game, character, version)
      expect(response).to have_http_status(:redirect)
    end
  end
end
