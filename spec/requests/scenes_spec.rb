require "rails_helper"

RSpec.describe "Scenes", type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:game_id/scenes (index)" do
    it "GM can access the scene index" do
      sign_in(gm)
      get game_scenes_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player can access the scene index" do
      sign_in(player)
      get game_scenes_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get game_scenes_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /games/:game_id/scenes/new" do
    it "GM can access the new scene form" do
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get new_game_scene_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end
  end

  describe "POST /games/:game_id/scenes" do
    it "GM can create a scene" do
      sign_in(gm)
      expect {
        post game_scenes_path(game), params: { scene: { title: "Test" } }
      }.to change(Scene, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "GM can create a scene with blank title (gets default)" do
      sign_in(gm)
      post game_scenes_path(game), params: { scene: { title: "" } }
      expect(Scene.last.title).to match(/\A\w+ \d+, \d{4}/)
    end

    it "player cannot create a scene" do
      sign_in(player)
      expect {
        post game_scenes_path(game), params: { scene: { title: "Sneaky" } }
      }.not_to change(Scene, :count)
      expect(response).to redirect_to(game_path(game))
    end
  end

  describe "PATCH /games/:game_id/scenes/:id/resolve" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
    end

    it "GM can resolve a scene" do
      sign_in(gm)
      patch resolve_game_scene_path(game, scene), params: { resolution: "Done." }
      expect(scene.reload).to be_resolved
    end

    it "player cannot resolve a scene" do
      create(:scene_participant, scene: scene, user: player)
      sign_in(player)
      patch resolve_game_scene_path(game, scene), params: { resolution: "Nope." }
      expect(scene.reload).not_to be_resolved
      expect(response).to redirect_to(game_scene_path(game, scene))
    end
  end
end
