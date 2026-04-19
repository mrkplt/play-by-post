require "rails_helper"

RSpec.describe CharactersController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:other_player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:game_member, game: game, user: other_player)
  end

  describe "GET /games/:game_id/characters/new" do
    it "GM can access the new character form" do
      sign_in(gm)
      get new_game_character_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player can access the new character form" do
      sign_in(player)
      get new_game_character_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get new_game_character_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /games/:game_id/characters" do
    context "as GM with no user_id selected" do
      it "renders :new with unprocessable_content" do
        sign_in(gm)
        post game_characters_path(game), params: { character: { name: "Hero", content: "content", user_id: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as GM with valid params" do
      it "creates character and redirects" do
        sign_in(gm)
        expect {
          post game_characters_path(game), params: { character: { name: "Hero", content: "content", user_id: player.id } }
        }.to change(Character, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "as player with valid params" do
      it "creates character and redirects" do
        sign_in(player)
        expect {
          post game_characters_path(game), params: { character: { name: "My Hero", content: "content" } }
        }.to change(Character, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid params (blank name)" do
      it "renders :new with unprocessable_content" do
        sign_in(player)
        post game_characters_path(game), params: { character: { name: "", content: "content" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /games/:game_id/characters/:id" do
    let(:character) { create(:character, game: game, user: player) }

    it "renders ok for a member" do
      sign_in(player)
      get game_character_path(game, character)
      expect(response).to have_http_status(:ok)
    end

    it "shows player email prefix when user has no display name" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      char = create(:character, game: game, user: player_no_name)
      sign_in(gm)
      get game_character_path(game, char)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "shows player display name when set" do
      player.user_profile.update!(display_name: "Elrond Half-Elven")
      char = create(:character, game: game, user: player)
      sign_in(gm)
      get game_character_path(game, char)
      expect(response.body).to include("Elrond Half-Elven")
    end

    it "shows version editor display name in version history" do
      char = create(:character, game: game, user: player)
      player.user_profile.update!(display_name: "Bilbo Baggins")
      char.character_versions.create!(content: "v1 content", edited_by: player)
      sign_in(gm)
      get game_character_path(game, char)
      expect(response.body).to include("Bilbo Baggins")
    end

    it "shows version editor email prefix when editor has no display name" do
      char = create(:character, game: game, user: player)
      nameless = create(:user)
      create(:game_member, game: game, user: nameless)
      char.character_versions.create!(content: "v2 content", edited_by: nameless)
      sign_in(gm)
      get game_character_path(game, char)
      expect(response.body).to include(nameless.email.split("@").first)
    end
  end

  describe "GET /games/:game_id/characters/:id/edit" do
    let(:character) { create(:character, game: game, user: player) }

    it "owner can access the edit form" do
      sign_in(player)
      get edit_game_character_path(game, character)
      expect(response).to have_http_status(:ok)
    end

    it "non-owner player is redirected" do
      sign_in(other_player)
      get edit_game_character_path(game, character)
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to match(/cannot edit/i)
    end

    it "GM can access another player's edit form" do
      sign_in(gm)
      get edit_game_character_path(game, character)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /games/:game_id/characters/:id" do
    let(:character) { create(:character, game: game, user: player) }

    it "updates with valid params and redirects" do
      sign_in(player)
      patch game_character_path(game, character), params: { character: { name: "Updated Name", content: "new content" } }
      expect(response).to redirect_to(game_character_path(game, character))
      expect(character.reload.name).to eq("Updated Name")
    end

    it "renders :edit with unprocessable_content on invalid params" do
      sign_in(player)
      patch game_character_path(game, character), params: { character: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /games/:game_id/characters/:id/archive" do
    let(:character) { create(:character, game: game, user: player) }

    it "GM can archive a character" do
      sign_in(gm)
      patch archive_game_character_path(game, character)
      expect(character.reload).to be_archived
      expect(response).to redirect_to(game_character_path(game, character))
    end

    it "player cannot archive a character" do
      sign_in(player)
      patch archive_game_character_path(game, character)
      expect(character.reload).not_to be_archived
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /games/:game_id/characters/:id/restore" do
    let(:character) { create(:character, :archived, game: game, user: player) }

    it "GM can restore an archived character" do
      sign_in(gm)
      patch restore_game_character_path(game, character)
      expect(character.reload.archived_at).to be_nil
      expect(response).to redirect_to(game_character_path(game, character))
    end

    it "player cannot restore a character" do
      sign_in(player)
      patch restore_game_character_path(game, character)
      expect(character.reload.archived_at).not_to be_nil
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "require_game_access! — banned user" do
    let(:character) { create(:character, game: game, user: player) }
    let(:banned_user) { create(:user, :with_profile) }

    before do
      create(:game_member, :banned, game: game, user: banned_user)
    end

    it "redirects to root with alert" do
      sign_in(banned_user)
      get game_character_path(game, character)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
    end
  end

  describe "set_character — hidden character" do
    let(:hidden_character) { create(:character, :hidden, game: game, user: player) }

    it "redirects non-owner non-GM to game path" do
      sign_in(other_player)
      get game_character_path(game, hidden_character)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/hidden/i)
    end

    it "allows owner to view their own hidden character" do
      sign_in(player)
      get game_character_path(game, hidden_character)
      expect(response).to have_http_status(:ok)
    end

    it "allows GM to view a hidden character" do
      sign_in(gm)
      get game_character_path(game, hidden_character)
      expect(response).to have_http_status(:ok)
    end
  end
end
