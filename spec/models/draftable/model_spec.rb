require "rails_helper"

# Draftable::Model supplies the shared draft?/published?/publish! behaviour to
# any record with a `draft` column. Tested through a probe that includes it and
# backs onto the existing `posts` table (which has the `draft` boolean), so the
# instance methods run against a real row without a synthetic schema. The
# per-model scopes and presence validation are declared on each model, not here,
# so they are covered by that model's own spec.
class DraftableProbe < ApplicationRecord
  self.table_name = "posts"
  include Draftable::Model
end

RSpec.describe Draftable::Model do
  let(:scene) { create(:scene) }

  def probe(draft:)
    DraftableProbe.new(scene_id: scene.id, user_id: create(:user).id,
                       draft: draft, content: "written")
  end

  describe "#draft?" do
    it "is true for a draft record" do
      expect(probe(draft: true).draft?).to be(true)
    end

    it "is false for a published record" do
      expect(probe(draft: false).draft?).to be(false)
    end
  end

  describe "#published?" do
    it "is false for a draft record" do
      expect(probe(draft: true).published?).to be(false)
    end

    it "is true for a published record" do
      expect(probe(draft: false).published?).to be(true)
    end
  end

  describe "#publish!" do
    it "promotes a draft to published in place" do
      record = probe(draft: true).tap(&:save!)

      record.publish!

      expect(record.reload.draft).to be(false)
    end

    it "leaves an already-published record published" do
      record = probe(draft: false).tap(&:save!)

      record.publish!

      expect(record.reload.draft).to be(false)
    end
  end
end
