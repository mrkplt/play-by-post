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

    it "records Current.user as edited_by when set" do
      gm = create(:user)
      Current.user = gm
      character = create(:character)
      expect(character.character_versions.last.edited_by_id).to eq(gm.id)
      Current.user = nil
    end

    it "falls back to character owner when Current.user is nil" do
      Current.user = nil
      character = create(:character)
      expect(character.character_versions.last.edited_by_id).to eq(character.user_id)
    end
  end

  describe ".visible_to" do
    let(:game) { create(:game) }
    let(:owner) { create(:user) }
    let(:other) { create(:user) }
    let(:gm_user) { create(:user) }

    before do
      create(:game_member, :game_master, game: game, user: gm_user)
      create(:game_member, game: game, user: owner)
      create(:game_member, game: game, user: other)
    end

    it "GM sees all characters regardless of sheets_hidden" do
      game.update!(sheets_hidden: true)
      create(:character, game: game, user: owner, name: "Visible")
      create(:character, :hidden, game: game, user: other, name: "Hidden")

      result = Character.visible_to(gm_user, game)
      expect(result.pluck(:name)).to contain_exactly("Visible", "Hidden")
    end

    it "when sheets_hidden, non-GM sees only own characters" do
      game.update!(sheets_hidden: true)
      own_char = create(:character, game: game, user: owner, name: "Mine")
      create(:character, game: game, user: other, name: "Theirs")

      result = Character.visible_to(owner, game)
      expect(result).to contain_exactly(own_char)
    end

    it "when sheets_hidden is false, normal visibility rules apply" do
      create(:character, game: game, user: owner, name: "Visible")
      hidden = create(:character, :hidden, game: game, user: other, name: "Hidden")

      result = Character.visible_to(owner, game)
      expect(result.pluck(:name)).to eq([ "Visible" ])
      expect(result).not_to include(hidden)
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
