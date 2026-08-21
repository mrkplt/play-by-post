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

  describe ".visible_to" do
    it "returns the relation unchanged when the viewer has no profile" do
      user = build_stubbed(:user, user_profile: nil)
      relation = described_class.all
      expect(described_class.visible_to(relation, user)).to equal(relation)
    end

    it "returns the relation unchanged when the viewer's preference is not hidden" do
      profile = build_stubbed(:user_profile, ai_display_preference: :tagged)
      user = build_stubbed(:user, user_profile: profile)
      relation = described_class.all
      expect(described_class.visible_to(relation, user)).to equal(relation)
    end

    it "excludes AI-generated rows when the viewer's preference is hidden" do
      profile = build_stubbed(:user_profile, ai_display_preference: :hidden)
      user = build_stubbed(:user, user_profile: profile)
      expect(described_class.visible_to(described_class.all, user).where_values_hash).to eq("generated_at" => nil)
    end

    it "filters the injected relation itself, not the bare class scope" do
      profile = build_stubbed(:user_profile, ai_display_preference: :hidden)
      user = build_stubbed(:user, user_profile: profile)
      relation = described_class.published

      expect(described_class.visible_to(relation, user).where_values_hash)
        .to eq("draft" => false, "generated_at" => nil)
    end

    it "excludes AI-generated summaries end to end when hidden", :db do
      game = create(:game)
      scene = create(:scene, :resolved, game: game, private: false)
      ai_summary = create(:scene_summary, :ai_generated, scene: scene)
      other_scene = create(:scene, :resolved, game: game, private: false)
      hand_written = create(:scene_summary, scene: other_scene)
      profile = create(:user_profile, ai_display_preference: :hidden)

      visible = described_class.visible_to(described_class.public_for_game(game), profile.user)

      expect(visible).to include(hand_written)
      expect(visible).not_to include(ai_summary)
    end

    it "includes AI-generated summaries when tagged", :db do
      game = create(:game)
      scene = create(:scene, :resolved, game: game, private: false)
      ai_summary = create(:scene_summary, :ai_generated, scene: scene)
      profile = create(:user_profile, ai_display_preference: :tagged)

      visible = described_class.visible_to(described_class.public_for_game(game), profile.user)

      expect(visible).to include(ai_summary)
    end
  end

  describe "#ai_generated?" do
    it "returns true when generated_at is present" do
      expect(build(:scene_summary, :ai_generated).ai_generated?).to be true
    end

    it "returns false when generated_at is nil" do
      expect(build(:scene_summary).ai_generated?).to be false
    end
  end

  describe "#edited?" do
    it "returns true when edited_at is present" do
      expect(build(:scene_summary, :edited).edited?).to be true
    end

    it "returns false when edited_at is nil" do
      expect(build(:scene_summary).edited?).to be false
    end
  end

  describe "#apply_manual_edit" do
    it "updates the body, editor, and edited_at", :db do
      editor = create(:user)
      summary = create(:scene_summary, body: "Old body")

      Timecop.freeze do
        summary.apply_manual_edit(body: "New body", editor: editor)
        expect(summary.body).to eq("New body")
        expect(summary.edited_by).to eq(editor)
        expect(summary.edited_at).to be_within(1.second).of(Time.current)
      end
    end

    it "clears AI generation metadata so a manually-edited summary is no longer AI-generated", :db do
      summary = create(:scene_summary, :ai_generated, input_tokens: 10, output_tokens: 20)
      editor = create(:user)

      summary.apply_manual_edit(body: "Hand-written", editor: editor)

      expect(summary.ai_generated?).to be(false)
      expect(summary.model_used).to be_nil
      expect(summary.input_tokens).to be_nil
      expect(summary.output_tokens).to be_nil
    end

    it "returns false and does not clear AI metadata when the body is blank", :db do
      summary = create(:scene_summary, :ai_generated)
      editor = create(:user)

      result = summary.apply_manual_edit(body: "", editor: editor)

      expect(result).to be(false)
      expect(summary.reload.ai_generated?).to be(true)
    end
  end
end
