require "rails_helper"

RSpec.describe CharacterImage, type: :model do
  it_behaves_like "an uploaded image", :character_image

  describe "#owner" do
    it "is the character" do
      character = build(:character)
      image = build(:character_image, character: character)
      expect(image.owner).to eq(character)
    end
  end

  describe "#siblings", :db do
    it "is the character's other images, excluding self" do
      character = create(:character)
      first = create(:character_image, character: character)
      second = create(:character_image, character: character)
      other_character_image = create(:character_image)

      expect(first.siblings).to contain_exactly(second)
      expect(first.siblings).not_to include(first, other_character_image)
    end
  end
end
