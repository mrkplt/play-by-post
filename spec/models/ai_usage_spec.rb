require "rails_helper"

RSpec.describe AiUsage, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:ai_usage)).to be_valid
    end

    it "requires feature" do
      expect(build(:ai_usage, feature: nil)).not_to be_valid
    end

    it "requires feature to be a known value" do
      expect(build(:ai_usage, feature: "unknown_feature")).not_to be_valid
    end

    it "accepts all known features" do
      AiUsage::FEATURES.each do |feature|
        expect(build(:ai_usage, feature: feature)).to be_valid
      end
    end

    it "requires model_used" do
      expect(build(:ai_usage, model_used: nil)).not_to be_valid
    end

    it "allows nil input_tokens" do
      expect(build(:ai_usage, input_tokens: nil)).to be_valid
    end

    it "allows nil output_tokens" do
      expect(build(:ai_usage, output_tokens: nil)).to be_valid
    end
  end

  describe "append-only enforcement" do
    it "raises ReadOnlyRecord on update" do
      record = create(:ai_usage)
      expect { record.update!(model_used: "other/model") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe ".for_feature" do
    it "returns records matching the given feature" do
      email_usage = create(:ai_usage, feature: "inbound_email")
      create(:ai_usage, feature: "scene_summary")

      expect(AiUsage.for_feature("inbound_email")).to contain_exactly(email_usage)
    end

    it "returns an empty relation when no records match" do
      create(:ai_usage, feature: "inbound_email")

      expect(AiUsage.for_feature("scene_summary")).to be_empty
    end
  end
end
