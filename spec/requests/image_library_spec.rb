require "rails_helper"

# ImageLibrary's shared CRUD (upload → validate → store → make current; set
# current; delete) is exercised through a real adopter, CharacterImagesController.
# Described as ImageLibrary so mutant attributes these examples to the module
# subject — mutant keys test selection to the described constant, so a spec
# describing only the concrete controller would leave the module unmeasured.
RSpec.describe ImageLibrary, type: :request do
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game, user: player) }

  before { create(:game_member, game: game, user: player) }

  let(:upload) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/test_image.png"), "image/png"
    )
  end

  describe "#create" do
    it "stores the uploaded image and makes it the current one" do
      sign_in(player)

      expect {
        post game_character_images_path(game, character), params: { image: { file: upload } }
      }.to change { character.character_images.count }.by(1)

      image = character.character_images.last
      expect(image.file).to be_attached
      expect(image.current?).to be(true)
      # In place: swap the library section, no character reload.
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
      expect(flash[:notice]).to eq("Image added.")
    end

    it "makes the newest upload current, clearing a prior current image" do
      previous = create(:character_image, :current, character: character)
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: upload } }

      expect(previous.reload.current?).to be(false)
      expect(character.character_images.order(:created_at).last.current?).to be(true)
    end

    it "passes the full upload context (kind, owner user+game, filename) to the uploader" do
      allow(AttachmentUploader).to receive(:attach).and_call_original
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: upload } }

      expect(AttachmentUploader).to have_received(:attach).with(
        hash_including(
          context: have_attributes(
            kind: "character_image",
            owner: have_attributes(user: player, game: game),
            naming: have_attributes(original_filename: "test_image.png")
          )
        )
      )
    end

    it "redirects with an alert when no file is provided" do
      sign_in(player)

      post game_character_images_path(game, character), params: { image: {} }

      expect(flash[:alert]).to eq("Please select an image to upload.")
    end

    it "redirects with an alert when the image param is not a file" do
      sign_in(player)

      post game_character_images_path(game, character), params: { image: { file: "not-a-file" } }

      expect(flash[:alert]).to eq("Please select an image to upload.")
      expect(character.character_images.count).to eq(0)
    end

    context "pre-upload validation (before touching R2)" do
      before { allow(AttachmentUploader).to receive(:attach) }

      it "rejects an oversized file without uploading" do
        oversized = Rack::Test::UploadedFile.new(
          StringIO.new("x" * (UploadedImage::Model::IMAGE_MAX_SIZE + 1)), "image/png",
          original_filename: "big.png"
        )
        sign_in(player)

        post game_character_images_path(game, character), params: { image: { file: oversized } }

        expect(AttachmentUploader).not_to have_received(:attach)
        expect(flash[:alert]).to eq("Image must be less than 10MB.")
      end

      it "accepts a file exactly at the size limit (boundary)" do
        at_limit = Rack::Test::UploadedFile.new(
          StringIO.new("x" * UploadedImage::Model::IMAGE_MAX_SIZE), "image/png",
          original_filename: "exact.png"
        )
        sign_in(player)

        post game_character_images_path(game, character), params: { image: { file: at_limit } }

        expect(AttachmentUploader).to have_received(:attach)
      end

      it "rejects a non-image content type without uploading" do
        pdf = Rack::Test::UploadedFile.new(
          StringIO.new("nope"), "application/pdf", original_filename: "doc.pdf"
        )
        sign_in(player)

        post game_character_images_path(game, character), params: { image: { file: pdf } }

        expect(AttachmentUploader).not_to have_received(:attach)
        expect(flash[:alert]).to eq("Image must be a JPEG, PNG, GIF, or WebP image.")
      end
    end
  end

  describe "#update (set current)" do
    it "makes the chosen image current and swaps the library in place" do
      first = create(:character_image, :current, character: character)
      second = create(:character_image, character: character)
      sign_in(player)

      patch game_character_image_path(game, character, second)

      expect(second.reload.current?).to be(true)
      expect(first.reload.current?).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
      expect(flash[:notice]).to eq("Image updated.")
    end
  end

  describe "#destroy" do
    it "deletes the image and swaps the library in place" do
      image = create(:character_image, character: character)
      sign_in(player)

      expect {
        delete game_character_image_path(game, character, image)
      }.to change { character.character_images.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_character_image")
      expect(flash[:notice]).to eq("Image deleted.")
    end
  end
end
