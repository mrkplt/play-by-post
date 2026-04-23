require "rails_helper"

RSpec.describe GamesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/new" do
    it "renders ok for authenticated user" do
      sign_in(gm)
      get new_game_path
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get new_game_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /games" do
    it "creates a game and adds the creator as GM" do
      sign_in(gm)
      expect {
        post games_path, params: { game: { name: "New Adventure" } }
      }.to change(Game, :count).by(1)
      new_game = Game.last
      expect(response).to redirect_to(game_path(new_game))
      expect(new_game.game_master?(gm)).to be true
    end

    it "renders new with unprocessable_content on invalid params" do
      sign_in(gm)
      post games_path, params: { game: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "unauthenticated user is redirected" do
      post games_path, params: { game: { name: "Adventure" } }
      expect(response).to have_http_status(:redirect)
    end
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

    it "shows characters in alphabetical order" do
      create(:character, game: game, user: player, name: "Zara the Bold")
      create(:character, game: game, user: player, name: "Aaron the Swift")
      sign_in(gm)
      get game_path(game)
      aaron_pos = response.body.index("Aaron the Swift")
      zara_pos = response.body.index("Zara the Bold")
      expect(aaron_pos).to be < zara_pos
    end

    it "does not show hidden characters to a non-owner player" do
      other = create(:user, :with_profile)
      create(:game_member, game: game, user: other)
      create(:character, :hidden, game: game, user: other, name: "Secret Character")
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Secret Character")
    end

    it "shows scenes sorted by most recent activity first" do
      older_scene = create(:scene, game: game, title: "Older Scene Title")
      create(:scene_participant, scene: older_scene, user: gm)
      create(:post, scene: older_scene, user: gm, created_at: 2.days.ago)

      newer_scene = create(:scene, game: game, title: "Newer Scene Title")
      create(:scene_participant, scene: newer_scene, user: gm)
      create(:post, scene: newer_scene, user: gm, created_at: 1.hour.ago)

      sign_in(gm)
      get game_path(game)
      older_pos = response.body.index("Older Scene Title")
      newer_pos = response.body.index("Newer Scene Title")
      expect(newer_pos).to be < older_pos
    end
  end

  describe "PATCH /games/:id/toggle_sheets_hidden" do
    it "GM can hide character sheets" do
      sign_in(gm)
      patch toggle_sheets_hidden_game_path(game)
      expect(game.reload.sheets_hidden?).to be true
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to match(/hidden/i)
    end

    it "GM can reveal character sheets" do
      game.update!(sheets_hidden: true)
      sign_in(gm)
      patch toggle_sheets_hidden_game_path(game)
      expect(game.reload.sheets_hidden?).to be false
      expect(flash[:notice]).to match(/visible/i)
    end

    it "player cannot toggle character sheet visibility" do
      sign_in(player)
      patch toggle_sheets_hidden_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.sheets_hidden?).to be false
    end
  end

  describe "require_game_access! — banned user" do
    let(:banned_user) { create(:user, :with_profile) }

    before do
      create(:game_member, :banned, game: game, user: banned_user)
    end

    it "redirects to root with alert on show" do
      sign_in(banned_user)
      get game_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
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
