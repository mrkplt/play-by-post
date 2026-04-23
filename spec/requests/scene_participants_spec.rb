require "rails_helper"

RSpec.describe SceneParticipantsController, type: :request do
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

    it "shows player email prefix when user has no display name" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "shows player display name when set" do
      player.user_profile.update!(display_name: "Samwise Gamgee")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).to include("Samwise Gamgee")
    end

    it "shows character name checkboxes for selection" do
      character = create(:character, game: game, user: player, name: "Aragorn Son of Arathorn")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).to include("Aragorn Son of Arathorn")
    end

    it "pre-checks the current participant character" do
      character = create(:character, game: game, user: player, name: "Boromir")
      scene.scene_participants.find_by(user: player).update!(character: character)
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).to match(/value="#{character.id}"[^>]*checked/)
    end

    it "does not show inactive characters" do
      create(:character, :archived, game: game, user: player, name: "Retired Knight")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).not_to include("Retired Knight")
    end

    it "does not show removed players" do
      removed = create(:user, :with_profile)
      removed.user_profile.update!(display_name: "Ex Member")
      create(:game_member, :removed, game: game, user: removed)
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).not_to include("Ex Member")
    end

    it "does not show the GM as a selectable participant" do
      create(:character, game: game, user: player, name: "Player Character")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      expect(response.body).not_to include("No active characters")
    end

    it "shows players in alphabetical order by display name" do
      player.user_profile.update!(display_name: "Zelda Zephyr")
      player2 = create(:user)
      create(:game_member, game: game, user: player2)
      create(:user_profile, user: player2, display_name: "Aaron Aardvark")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      aaron_pos = response.body.index("Aaron Aardvark")
      zelda_pos = response.body.index("Zelda Zephyr")
      expect(aaron_pos).to be < zelda_pos
    end

    it "shows characters in alphabetical order under each player" do
      create(:character, game: game, user: player, name: "Zara the Fierce")
      create(:character, game: game, user: player, name: "Aaron the Brave")
      sign_in(gm)
      get edit_game_scene_participants_path(game, scene)
      aaron_pos = response.body.index("Aaron the Brave")
      zara_pos = response.body.index("Zara the Fierce")
      expect(aaron_pos).to be < zara_pos
    end
  end

  describe "PATCH /games/:game_id/scenes/:scene_id/participants" do
    it "assigns the selected character to the participant row" do
      character = create(:character, game: game, user: player)
      sign_in(gm)
      patch game_scene_participants_path(game, scene), params: { character_ids: [ character.id ] }
      expect(response).to redirect_to(game_scene_path(game, scene))
      sp = scene.scene_participants.find_by(user: player)
      expect(sp).not_to be_nil
      expect(sp.character_id).to eq(character.id)
    end

    it "removes participants whose characters were deselected" do
      other_player = create(:user, :with_profile)
      create(:game_member, game: game, user: other_player)
      create(:scene_participant, scene: scene, user: other_player)
      sign_in(gm)
      # Pass empty character_ids — other_player should be removed
      patch game_scene_participants_path(game, scene), params: { character_ids: [] }
      expect(scene.scene_participants.where(user: other_player)).not_to exist
    end

    it "always keeps the GM as a participant" do
      sign_in(gm)
      patch game_scene_participants_path(game, scene), params: { character_ids: [] }
      expect(scene.scene_participants.where(user: gm)).to exist
    end

    it "player cannot update participants" do
      sign_in(player)
      patch game_scene_participants_path(game, scene), params: { character_ids: [] }
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:alert]).to match(/only the gm/i)
    end
  end

  describe "POST /games/:game_id/scenes/:scene_id/participants/join" do
    it "player can join a public non-resolved scene" do
      new_player = create(:user, :with_profile)
      create(:game_member, game: game, user: new_player)
      sign_in(new_player)
      post join_game_scene_participants_path(game, scene)
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:notice]).to match(/joined/i)
    end

    it "player cannot join a private scene" do
      private_scene = create(:scene, :private, game: game)
      sign_in(player)
      post join_game_scene_participants_path(game, private_scene)
      expect(response).to redirect_to(game_scene_path(game, private_scene))
      expect(flash[:alert]).to match(/private/i)
    end

    it "GM can join a private scene" do
      private_scene = create(:scene, :private, game: game)
      sign_in(gm)
      post join_game_scene_participants_path(game, private_scene)
      expect(response).to redirect_to(game_scene_path(game, private_scene))
      expect(flash[:notice]).to match(/joined/i)
    end

    it "player cannot join a resolved scene" do
      resolved_scene = create(:scene, :resolved, game: game)
      sign_in(player)
      post join_game_scene_participants_path(game, resolved_scene)
      expect(response).to redirect_to(game_scene_path(game, resolved_scene))
      expect(flash[:alert]).to match(/resolved/i)
    end

    it "unauthenticated user is redirected" do
      post join_game_scene_participants_path(game, scene)
      expect(response).to have_http_status(:redirect)
    end
  end
end
