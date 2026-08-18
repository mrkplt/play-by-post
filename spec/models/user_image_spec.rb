require "rails_helper"

RSpec.describe UserImage, type: :model do
  it_behaves_like "an uploaded image", :user_image

  describe "#owner" do
    it "is the user" do
      user = build(:user)
      image = build(:user_image, user: user)
      expect(image.owner).to eq(user)
    end
  end

  describe "#siblings", :db do
    it "is the user's other images, excluding self" do
      user = create(:user)
      first = create(:user_image, user: user)
      second = create(:user_image, user: user)
      other_user_image = create(:user_image)

      expect(first.siblings).to contain_exactly(second)
      expect(first.siblings).not_to include(first, other_user_image)
    end
  end
end
