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

  # No persistence: the scope's job is to build the right query, and ActiveRecord
  # is responsible for executing it. Asserting on to_sql exercises our branching
  # without inserting the game/members/characters each example previously needed.
  describe ".visible_to" do
    let(:viewer) { build_stubbed(:user) }
    let(:game) { instance_double(Game) }

    it "GM sees every character regardless of sheets_hidden" do
      allow(game).to receive(:game_master?).with(viewer).and_return(true)

      expect(Character.visible_to(viewer, game).to_sql).to eq(Character.all.to_sql)
    end

    it "when sheets_hidden, a non-GM is restricted to their own characters" do
      allow(game).to receive(:game_master?).with(viewer).and_return(false)
      allow(game).to receive(:sheets_hidden?).and_return(true)

      sql = Character.visible_to(viewer, game).to_sql
      expect(sql).to include(%{"characters"."user_id" = #{viewer.id}})
      expect(sql).not_to include(%{"characters"."hidden"})
    end

    it "when sheets_hidden is false, unhidden characters and the viewer's own are visible" do
      allow(game).to receive(:game_master?).with(viewer).and_return(false)
      allow(game).to receive(:sheets_hidden?).and_return(false)

      sql = Character.visible_to(viewer, game).to_sql
      expect(sql).to include(%{"characters"."hidden" = FALSE})
      expect(sql).to include(%{"characters"."user_id" = #{viewer.id}})
      expect(sql).to include(" OR ")
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
