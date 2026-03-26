require "rails_helper"

RSpec.describe "SceneParticipants", type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  describe "GET /games/:game_id/scenes/:scene_id/participants/edit" do
    it "GM can access edit participants" do
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get edit_game_scene_participants_path(game, scene)
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:alert]).to match(/only the gm/i)
    end
  end

  describe "PATCH /games/:game_id/scenes/:scene_id/participants" do
    it "GM can update participants" do
      character = create(:character, game: game, user: player)
      sign_in(gm)
      patch game_scene_participants_path(game, scene), params: { character_ids: [ character.id ] }
      expect(response).to redirect_to(game_scene_path(game, scene))
    end

    it "player cannot update participants" do
      sign_in(player)
      patch game_scene_participants_path(game, scene), params: { character_ids: [] }
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:alert]).to match(/only the gm/i)
    end
  end
end
