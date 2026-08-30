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

      # In place: swap the portrait library section + toast, no character reload.
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
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

    it "responds in place with an alert when no file is provided" do
      sign_in(player)

      post game_character_images_path(game, character), params: { image: {} }

      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to eq("Please select an image to upload.")
    end

    it "rejects an oversized file BEFORE touching storage (no orphaned blob)" do
      allow(AttachmentUploader).to receive(:attach)
      oversized = Rack::Test::UploadedFile.new(
        StringIO.new("x" * (UploadedImage::Model::IMAGE_MAX_SIZE + 1)), "image/png",
        original_filename: "big.png"
      )
      sign_in(player)

      expect {
        post game_character_images_path(game, character), params: { image: { file: oversized } }
      }.not_to change { character.character_images.count }

      expect(AttachmentUploader).not_to have_received(:attach)
      expect(flash[:alert]).to eq("Image must be less than 10MB.")
    end

    it "rejects a non-image file BEFORE touching storage" do
      allow(AttachmentUploader).to receive(:attach)
      pdf = Rack::Test::UploadedFile.new(
        StringIO.new("not an image"), "application/pdf", original_filename: "doc.pdf"
      )
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: pdf } }

      expect(AttachmentUploader).not_to have_received(:attach)
      expect(flash[:alert]).to eq("Image must be a JPEG, PNG, GIF, or WebP image.")
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
    # The Save button (image-select Stimulus controller) hits this exact
    # endpoint via fetch with a turbo-stream Accept header — the request spec
    # exercises that, not a plain form PATCH, since that is the only way this
    # action is reached now that the "Use" button_to is gone.
    it "makes the chosen image current and answers with the in-place library swap + toast" do
      first = create(:character_image, :current, character: character)
      second = create(:character_image, character: character)
      sign_in(player)

      patch game_character_image_path(game, character, second),
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(second.reload.current?).to be(true)
      expect(first.reload.current?).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
      expect(response.body).to include("toast_layer")
    end
  end

  describe "DELETE /games/:game_id/characters/:character_id/images/:id" do
    it "deletes the image" do
      image = create(:character_image, character: character)
      sign_in(player)

      expect {
        delete game_character_image_path(game, character, image)
      }.to change { character.character_images.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
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
