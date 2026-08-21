require "rails_helper"

RSpec.describe SceneSummary, type: :model do
  describe "associations" do
    it "belongs to scene" do
      scene = create(:scene)
      summary = create(:scene_summary, scene: scene)
      expect(summary.scene).to eq(scene)
    end

    it "belongs to edited_by (optional)" do
      summary = build(:scene_summary, edited_by: nil)
      expect(summary).to be_valid
    end

    it "belongs to generated_by (optional)" do
      summary = build(:scene_summary, generated_by: nil)
      expect(summary).to be_valid
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:scene_summary)).to be_valid
    end

    it "requires body when published" do
      expect(build(:scene_summary, body: "", draft: false)).not_to be_valid
    end

    it "allows a blank body when a draft" do
      summary = build(:scene_summary, body: "", draft: true)
      summary.valid?
      expect(summary.errors[:body]).to be_empty
    end
  end

  describe "draft scopes" do
    it ".published selects only non-drafts" do
      expect(described_class.published.where_values_hash).to eq("draft" => false)
    end

    it ".drafts selects only drafts" do
      expect(described_class.drafts.where_values_hash).to eq("draft" => true)
    end
  end

  describe ".public_for_game" do
    let(:game) { create(:game) }

    it "includes summaries of public resolved scenes", :db do
      scene = create(:scene, :resolved, game: game, private: false)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).to include(summary)
    end

    it "excludes summaries of private scenes", :db do
      scene = create(:scene, :resolved, game: game, private: true)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "excludes draft summaries — an unpublished summary never reaches the log or feed", :db do
      scene = create(:scene, :resolved, game: game, private: false)
      draft = create(:scene_summary, scene: scene, draft: true)
      expect(described_class.public_for_game(game)).not_to include(draft)
    end

    it "excludes summaries of unresolved scenes", :db do
      scene = create(:scene, game: game, private: false)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "excludes summaries from other games", :db do
      other_scene = create(:scene, :resolved, private: false)
      summary = create(:scene_summary, scene: other_scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "orders by scene resolved_at descending", :db do
      older = create(:scene, :resolved, game: game, private: false, resolved_at: 2.days.ago)
      newer = create(:scene, :resolved, game: game, private: false, resolved_at: 1.day.ago)
      older_summary = create(:scene_summary, scene: older)
      newer_summary = create(:scene_summary, scene: newer)
      expect(described_class.public_for_game(game).to_a).to eq([ newer_summary, older_summary ])
    end
  end

  # ai_generated?/edited?/apply_manual_edit are AiGenerated::Model's shared
  # behaviour, covered by spec/models/ai_generated/model_spec.rb. SceneSummary
  # includes it (see app/models/scene_summary.rb) but does not re-test it here.
end
