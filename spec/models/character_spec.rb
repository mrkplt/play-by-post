require "rails_helper"

RSpec.describe Character, type: :model do
  describe "validations" do
    it "requires a name" do
      expect(build(:character, name: nil)).not_to be_valid
    end

    it "is valid with required attributes" do
      expect(build(:character)).to be_valid
    end
  end

  describe "version snapshots" do
    it "creates a version on save" do
      character = create(:character)
      expect(character.character_versions.count).to eq(1)
    end

    it "creates a new version on each update" do
      character = create(:character)
      character.update!(content: "Updated content")
      expect(character.character_versions.count).to eq(2)
    end
  end

  describe "#editable_by?" do
    let(:game) { create(:game) }
    let(:owner) { create(:user) }
    let(:other) { create(:user) }
    let(:gm_user) { create(:user) }
    let(:character) { create(:character, game: game, user: owner) }

    before do
      create(:game_member, :game_master, game: game, user: gm_user)
      create(:game_member, game: game, user: owner)
      create(:game_member, game: game, user: other)
    end

    it "returns true for the owner" do
      expect(character.editable_by?(owner, game)).to be true
    end

    it "returns true for the GM" do
      expect(character.editable_by?(gm_user, game)).to be true
    end

    it "returns false for another player" do
      expect(character.editable_by?(other, game)).to be false
    end
  end
end
