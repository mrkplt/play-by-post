require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "associations" do
    it "belongs to user" do
      association = Feedback.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build_stubbed(:feedback)).to be_valid
    end

    it "requires a body" do
      feedback = build_stubbed(:feedback, body: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:body]).to be_present
    end

    it "does not require a url" do
      expect(build_stubbed(:feedback, url: nil)).to be_valid
    end
  end

  describe ".unswept" do
    it "selects entries that have not been swept into Fizzy" do
      sql = unquoted_sql(Feedback.unswept)

      expect(sql).to include("feedback.swept_at IS NULL")
    end
  end
end
