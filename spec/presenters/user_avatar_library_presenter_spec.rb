require "rails_helper"

RSpec.describe UserAvatarLibraryPresenter, :db do
  let(:user) { create(:user) }
  # A view-context stand-in exposing exactly the URL + variant helpers the
  # presenter calls; end-to-end URL correctness is covered by the request specs.
  let(:helpers) do
    double("helpers").tap do |h|
      allow(h).to receive(:url_for) { |variant| "/blob/#{variant.object_id}" }
      allow(h).to receive(:profile_images_path).and_return("/profile/images")
      allow(h).to receive(:profile_image_path).with(anything) { |image| "/profile/images/#{image.id}" }
    end
  end

  subject(:presenter) { described_class.new(user: user, helpers: helpers) }

  describe "#items" do
    it "builds one Item per image, newest first" do
      older = create(:user_image, :with_file, user: user)
      newer = create(:user_image, :with_file, :current, user: user)

      items = presenter.items

      expect(items.map { |i| i[:id] }).to eq([ newer.id, older.id ])
      expect(items.first[:current]).to be(true)
    end

    it "eager-loads the attachments so the blobs are not an N+1" do
      create(:user_image, :with_file, user: user)
      create(:user_image, :with_file, user: user)

      images = presenter.send(:images).to_a
      expect(images).to all(satisfy { |img| img.file.attachment.association(:blob).loaded? })
    end

    it "points the URLs at the profile image route" do
      image = create(:user_image, :with_file, user: user)

      item = presenter.items.first
      expect(item[:set_current_url]).to eq("/profile/images/#{image.id}")
      expect(item[:delete_url]).to eq("/profile/images/#{image.id}")
    end
  end

  describe "#upload_url" do
    it "is the profile images collection path" do
      expect(presenter.upload_url).to eq("/profile/images")
    end
  end

  describe "#can_manage?" do
    it "is always true — the profile is the acting user's own" do
      expect(presenter.can_manage?).to be(true)
    end
  end
end
