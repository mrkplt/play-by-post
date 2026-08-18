require "rails_helper"

RSpec.describe CharacterImagesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game, user: player) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  let(:upload) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/test_image.png"), "image/png"
    )
  end

  describe "POST /games/:game_id/characters/:character_id/images" do
    it "uploads via AttachmentUploader with character_image context and stores the image" do
      sign_in(player)

      expect {
        post game_character_images_path(game, character), params: { image: { file: upload } }
      }.to change { character.character_images.count }.by(1)

      expect(response).to redirect_to(game_character_path(game, character))
      expect(character.character_images.last.file).to be_attached
    end

    it "marks the newly uploaded image current" do
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: upload } }

      expect(character.character_images.last.current?).to be(true)
    end

    it "sets the uploader context kind to character_image" do
      allow(AttachmentUploader).to receive(:attach).and_call_original
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: upload } }

      expect(AttachmentUploader).to have_received(:attach).with(
        hash_including(
          context: have_attributes(
            kind: "character_image",
            owner: have_attributes(user: player, game: game)
          )
        )
      )
    end

    it "denies the GM — portraits are curated by the owning player only" do
      sign_in(gm)

      expect {
        post game_character_images_path(game, character), params: { image: { file: upload } }
      }.not_to change { character.character_images.count }
    end

    it "redirects with an alert when no file is provided" do
      sign_in(player)

      post game_character_images_path(game, character), params: { image: {} }

      expect(response).to redirect_to(game_character_path(game, character))
      expect(flash[:alert]).to eq("Please select an image to upload.")
    end

    it "denies a player who does not own the character" do
      other = create(:user, :with_profile)
      create(:game_member, game: game, user: other)
      sign_in(other)

      expect {
        post game_character_images_path(game, character), params: { image: { file: upload } }
      }.not_to change { character.character_images.count }
    end

    it "denies a non-member of the game" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)

      post game_character_images_path(game, character), params: { image: { file: upload } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have access to this game.")
    end
  end

  describe "PATCH /games/:game_id/characters/:character_id/images/:id" do
    it "makes the chosen image current" do
      first = create(:character_image, :current, character: character)
      second = create(:character_image, character: character)
      sign_in(player)

      patch game_character_image_path(game, character, second)

      expect(second.reload.current?).to be(true)
      expect(first.reload.current?).to be(false)
      expect(response).to redirect_to(game_character_path(game, character))
    end
  end

  describe "DELETE /games/:game_id/characters/:character_id/images/:id" do
    it "deletes the image" do
      image = create(:character_image, character: character)
      sign_in(player)

      expect {
        delete game_character_image_path(game, character, image)
      }.to change { character.character_images.count }.by(-1)

      expect(response).to redirect_to(game_character_path(game, character))
    end

    it "denies a player who does not own the character" do
      image = create(:character_image, character: character)
      other = create(:user, :with_profile)
      create(:game_member, game: game, user: other)
      sign_in(other)

      expect {
        delete game_character_image_path(game, character, image)
      }.not_to change { character.character_images.count }
    end
  end
end
