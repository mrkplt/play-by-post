require "rails_helper"

# Draftable::Presentation delegates through a BasePresenter's SimpleDelegator
# target, so the probe is a BasePresenter subclass wrapping a real model that
# carries Draftable::Model. Post is that model — it includes Draftable::Model
# and backs onto a table with the draft column.
class DraftablePresenterProbe < BasePresenter
  include Draftable::Presentation
end

RSpec.describe Draftable::Presentation do
  let(:scene) { create(:scene) }
  let(:user) { create(:user) }

  def present(draft:)
    post = build(:post, scene: scene, user: user, draft: draft,
                        content: draft ? nil : "written")
    DraftablePresenterProbe.new(post)
  end

  describe "#draft?" do
    it "is true for a draft record" do
      expect(present(draft: true).draft?).to be(true)
    end

    it "is false for a published record" do
      expect(present(draft: false).draft?).to be(false)
    end
  end

  describe "#draft_status_label" do
    it "labels a draft" do
      expect(present(draft: true).draft_status_label).to eq("Draft")
    end

    it "labels a published record" do
      expect(present(draft: false).draft_status_label).to eq("Published")
    end
  end

  describe "#hidden_from_players?" do
    it "hides a draft from players" do
      expect(present(draft: true).hidden_from_players?).to be(true)
    end

    it "does not hide a published record" do
      expect(present(draft: false).hidden_from_players?).to be(false)
    end
  end
end
