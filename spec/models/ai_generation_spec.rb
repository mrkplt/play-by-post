require "rails_helper"

RSpec.describe AiGeneration, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:ai_generation)).to be_valid
    end

    it "requires feature" do
      expect(build(:ai_generation, feature: nil)).not_to be_valid
    end

    it "requires feature to be a known value" do
      expect(build(:ai_generation, feature: "unknown_feature")).not_to be_valid
    end

    it "accepts all known features" do
      Ai::Feature.names.each do |feature|
        expect(build(:ai_generation, feature: feature)).to be_valid
      end
    end

    it "requires model_used" do
      expect(build(:ai_generation, model_used: nil)).not_to be_valid
    end

    it "requires requested_by_id" do
      expect(build(:ai_generation, requested_by_id: nil)).not_to be_valid
    end

    it "requires funded_by_id" do
      expect(build(:ai_generation, funded_by_id: nil)).not_to be_valid
    end

    it "requires asset_type" do
      expect(build(:ai_generation, asset_type: nil)).not_to be_valid
    end

    it "requires asset_id" do
      expect(build(:ai_generation, asset_id: nil)).not_to be_valid
    end

    it "allows nil input_tokens" do
      expect(build(:ai_generation, input_tokens: nil)).to be_valid
    end

    it "allows nil output_tokens" do
      expect(build(:ai_generation, output_tokens: nil)).to be_valid
    end

    it "allows nil cost" do
      expect(build(:ai_generation, cost: nil)).to be_valid
    end

    it "allows requested_by_id and funded_by_id to be equal" do
      user = create(:user)
      expect(build(:ai_generation, requested_by_id: user.id, funded_by_id: user.id)).to be_valid
    end
  end

  describe "append-only enforcement" do
    it "raises ReadOnlyRecord on update" do
      record = create(:ai_generation)
      expect { record.update!(model_used: "other/model") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises ReadOnlyRecord on destroy" do
      record = create(:ai_generation)
      expect { record.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "is not readonly before the record is persisted" do
      expect(build(:ai_generation)).not_to be_readonly
    end
  end

  describe "no cascade can reach an audit row", :db do
    it "survives the destruction of the SceneSummary it references" do
      summary = create(:scene_summary, :ai_generated)
      generation = create(:ai_generation, asset_type: "SceneSummary", asset_id: summary.id)

      SceneSummary.connection.execute("DELETE FROM scene_summaries WHERE id = #{summary.id}")

      expect(AiGeneration.find(generation.id)).to eq(generation)
    end

    it "survives the destruction of the Scene the summary belongs to" do
      scene = create(:scene)
      summary = create(:scene_summary, :ai_generated, scene: scene)
      generation = create(:ai_generation, asset_type: "SceneSummary", asset_id: summary.id)

      SceneSummary.connection.execute("DELETE FROM scene_summaries WHERE id = #{summary.id}")
      scene.destroy

      expect(AiGeneration.find(generation.id)).to eq(generation)
    end

    it "survives the destruction of the Game the scene belongs to" do
      game = create(:game)
      scene = create(:scene, game: game)
      summary = create(:scene_summary, :ai_generated, scene: scene)
      generation = create(:ai_generation, asset_type: "SceneSummary", asset_id: summary.id)

      SceneSummary.connection.execute("DELETE FROM scene_summaries WHERE id = #{summary.id}")
      scene.destroy
      game.destroy

      expect(AiGeneration.find(generation.id)).to eq(generation)
    end

    it "survives the destruction of the User whose id appears in requested_by_id" do
      requester = create(:user)
      funder = create(:user)
      generation = create(:ai_generation, requested_by_id: requester.id, funded_by_id: funder.id)

      requester.destroy

      expect(AiGeneration.find(generation.id)).to eq(generation)
    end

    it "survives the destruction of the User whose id appears in funded_by_id" do
      requester = create(:user)
      funder = create(:user)
      generation = create(:ai_generation, requested_by_id: requester.id, funded_by_id: funder.id)

      funder.destroy

      expect(AiGeneration.find(generation.id)).to eq(generation)
    end
  end
end
