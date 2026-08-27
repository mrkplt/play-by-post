require "rails_helper"

# AiGenerated::Model supplies the shared ai_generated?/edited?/apply_manual_edit
# behaviour to any record with the provenance column (generated_at) and
# edited_at/edited_by_id/body. Tested through a probe that includes it and
# backs onto the existing `scene_summaries` table, so the instance methods run
# against a real row without a synthetic schema — the same approach
# Draftable::Model's spec takes against `posts`.
class AiGeneratedProbe < ApplicationRecord
  self.table_name = "scene_summaries"
  include AiGenerated::Model

  belongs_to :edited_by, class_name: "User", optional: true

  # SceneSummary declares this same presence-unless-draft validation itself
  # (Draftable::Model philosophy: per-model wiring, not concern behaviour).
  # Mirrored here only so the "blank body returns false" #apply_manual_edit
  # case has something to fail against on the probe.
  validates :body, presence: true, unless: :draft?
end

RSpec.describe AiGenerated::Model do
  let(:scene) { create(:scene) }

  def probe(**attributes)
    AiGeneratedProbe.new({ scene_id: scene.id, body: "written" }.merge(attributes))
  end

  describe "#ai_generated?" do
    it "is true when generated_at is present" do
      expect(probe(generated_at: Time.current).ai_generated?).to be(true)
    end

    it "is false when generated_at is nil" do
      expect(probe(generated_at: nil).ai_generated?).to be(false)
    end
  end

  describe "#edited?" do
    it "is true when edited_at is present" do
      expect(probe(edited_at: Time.current).edited?).to be(true)
    end

    it "is false when edited_at is nil" do
      expect(probe(edited_at: nil).edited?).to be(false)
    end
  end

  describe "#apply_manual_edit" do
    it "updates the body, editor, and edited_at", :db do
      editor = create(:user)
      record = probe(body: "Old body").tap(&:save!)

      Timecop.freeze do
        record.apply_manual_edit(body: "New body", editor: editor)

        expect(record.body).to eq("New body")
        expect(record.edited_by).to eq(editor)
        expect(record.edited_at).to be_within(1.second).of(Time.current)
      end
    end

    it "clears generated_at so the record is no longer AI-generated", :db do
      editor = create(:user)
      record = probe(generated_at: Time.current).tap(&:save!)

      record.apply_manual_edit(body: "Hand-written", editor: editor)

      expect(record.ai_generated?).to be(false)
      expect(record.generated_at).to be_nil
    end

    it "returns false and does not clear AI metadata when the body is blank", :db do
      record = probe(generated_at: Time.current, draft: false, body: "Has content").tap(&:save!)
      editor = create(:user)

      result = record.apply_manual_edit(body: "", editor: editor)

      expect(result).to be(false)
      expect(record.reload.ai_generated?).to be(true)
    end
  end
end
