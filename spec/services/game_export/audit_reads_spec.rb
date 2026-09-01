require "rails_helper"

RSpec.describe GameExport::AuditReads, :db do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:summary) { create(:scene_summary, scene: scene) }

  describe ".generations_for" do
    it "returns the audit rows whose asset belongs to the game, oldest first" do
      older = create(:ai_generation, asset_type: "SceneSummary", asset_id: summary.id, created_at: 2.days.ago)
      newer = create(:ai_generation, asset_type: "SceneSummary", asset_id: summary.id, created_at: 1.day.ago)

      expect(described_class.generations_for(game)).to eq([ older, newer ])
    end

    it "excludes rows for a summary in another game's scene" do
      other_summary = create(:scene_summary, scene: create(:scene, game: create(:game)))
      create(:ai_generation, asset_type: "SceneSummary", asset_id: other_summary.id)

      expect(described_class.generations_for(game)).to be_empty
    end

    it "ignores rows of an asset_type with no game-scoping rule" do
      create(:ai_generation, asset_type: "SomethingElse", asset_id: 1)

      expect(described_class.generations_for(game)).to be_empty
    end
  end

  describe ".names_for" do
    it "maps requester and funder ids to display names in one read" do
      requester = create(:user, :with_profile)
      funder = create(:user, :with_profile)
      generation = build_stubbed(:ai_generation, requested_by_id: requester.id, funded_by_id: funder.id)

      names = described_class.names_for([ generation ])

      expect(names[requester.id]).to eq(requester.display_name)
      expect(names[funder.id]).to eq(funder.display_name)
    end

    it "omits users who no longer exist, so their cell is blank" do
      generation = build_stubbed(:ai_generation, requested_by_id: 999_999, funded_by_id: 999_998)

      expect(described_class.names_for([ generation ])).to be_empty
    end
  end
end
