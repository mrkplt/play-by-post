require "rails_helper"

RSpec.describe UserImagesController, type: :request do
  let(:user) { create(:user, :with_profile) }

  let(:upload) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/test_image.png"), "image/png"
    )
  end

  describe "POST /profile/images" do
    it "uploads via AttachmentUploader with user_image context and stores the image" do
      sign_in(user)

      expect {
        post profile_images_path, params: { image: { file: upload } }
      }.to change { user.user_images.count }.by(1)

      # In place: swap the avatar library section + toast, no profile reload.
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_user_image")
      expect(user.user_images.reload.last.file).to be_attached
    end

    it "marks the newly uploaded image current" do
      sign_in(user)

      post profile_images_path, params: { image: { file: upload } }

      expect(user.user_images.reload.last.current?).to be(true)
    end

    it "sets the uploader context kind to user_image with no game" do
      allow(AttachmentUploader).to receive(:attach).and_call_original
      sign_in(user)

      post profile_images_path, params: { image: { file: upload } }

      expect(AttachmentUploader).to have_received(:attach).with(
        hash_including(
          context: have_attributes(
            kind: "user_image",
            owner: have_attributes(user: user, game: nil)
          )
        )
      )
    end

    it "responds in place with an alert when no file is provided" do
      sign_in(user)

      post profile_images_path, params: { image: {} }

      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to eq("Please select an image to upload.")
    end

    it "requires authentication" do
      post profile_images_path, params: { image: { file: upload } }

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /profile/images/:id" do
    it "makes the chosen image current" do
      first = create(:user_image, :current, user: user)
      second = create(:user_image, user: user)
      sign_in(user)

      patch profile_image_path(second)

      expect(second.reload.current?).to be(true)
      expect(first.reload.current?).to be(false)
    end

    it "cannot touch another user's image" do
      other = create(:user, :with_profile)
      their_image = create(:user_image, :current, user: other)
      sign_in(user)

      patch profile_image_path(their_image)

      # The lookup is scoped to current_user's library, so another user's image
      # is simply not found — never reachable, current flag untouched.
      expect(response).to redirect_to(root_path)
      expect(their_image.reload.current?).to be(true)
    end
  end

  describe "DELETE /profile/images/:id" do
    it "deletes the image" do
      image = create(:user_image, user: user)
      sign_in(user)

      expect {
        delete profile_image_path(image)
      }.to change { user.user_images.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("image_library_user_image")
    end
  end
end
