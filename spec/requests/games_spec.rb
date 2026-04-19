require "rails_helper"

RSpec.describe GamesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:id/edit" do
    it "GM can access the edit form" do
      sign_in(gm)
      get edit_game_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get edit_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "unauthenticated user is redirected" do
      get edit_game_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /games/:id" do
    it "GM can update the game" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "Updated Name" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.name).to eq("Updated Name")
    end

    it "GM can update the description" do
      sign_in(gm)
      patch game_path(game), params: { game: { description: "New desc" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.description).to eq("New desc")
    end

    it "renders edit on invalid params" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "player cannot update the game" do
      sign_in(player)
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.name).not_to eq("Hacked")
    end

    it "unauthenticated user is redirected" do
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /games/:id" do
    it "shows character player email prefix when no display name is set" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      create(:character, game: game, user: player_no_name, name: "Spark")
      sign_in(gm)
      get game_path(game)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "shows character owner display name when set" do
      player.user_profile.update!(display_name: "Frodo Baggins")
      create(:character, game: game, user: player, name: "Ring Bearer")
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Frodo Baggins")
    end

    it "shows active scene titles in the active scenes section" do
      scene = create(:scene, game: game, title: "The Fellowship Meets")
      create(:scene_participant, scene: scene, user: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("The Fellowship Meets")
    end

    it "does not show resolved scene titles in the active scenes section" do
      resolved = create(:scene, :resolved, game: game, title: "Finished Quest")
      create(:scene_participant, scene: resolved, user: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("Finished Quest")
    end

    it "does not show private scenes to non-participants in the active scenes section" do
      private_scene = create(:scene, :private, game: game, title: "Secret Council")
      create(:scene_participant, scene: private_scene, user: gm)
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Secret Council")
    end

    it "shows active scenes to participants" do
      public_scene = create(:scene, game: game, title: "Open Battle")
      create(:scene_participant, scene: public_scene, user: player)
      sign_in(player)
      get game_path(game)
      expect(response.body).to include("Open Battle")
    end

    it "does not show archived characters in the character roster" do
      archived = create(:character, :archived, game: game, user: player, name: "Retired Hero")
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("Retired Hero")
    end

    it "shows the Export Game button when not rate limited" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Export Game")
    end

    it "shows GM management controls for GM" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("New Scene")
    end

    it "does not show New Scene button to non-GM player" do
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("New Scene")
    end
  end

  describe "PATCH /games/:id/toggle_images_disabled" do
    it "GM can disable image attachments" do
      sign_in(gm)
      patch toggle_images_disabled_game_path(game)
      expect(game.reload.images_disabled?).to be true
      expect(response).to redirect_to(edit_game_path(game))
      expect(flash[:notice]).to match(/disabled/i)
    end

    it "GM can re-enable image attachments" do
      game.update!(images_disabled: true)
      sign_in(gm)
      patch toggle_images_disabled_game_path(game)
      expect(game.reload.images_disabled?).to be false
      expect(response).to redirect_to(edit_game_path(game))
      expect(flash[:notice]).to match(/enabled/i)
    end

    it "player cannot toggle image attachments" do
      sign_in(player)
      patch toggle_images_disabled_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.images_disabled?).to be false
    end
  end
end
