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

  describe "#sweep" do
    before do
      allow(FizzySweepService).to receive(:create_card)
    end

    it "creates a Fizzy card and stamps swept_at" do
      feedback = build(:feedback)
      expect(feedback).to receive(:update!).with(swept_at: instance_of(ActiveSupport::TimeWithZone))

      feedback.sweep

      expect(FizzySweepService).to have_received(:create_card).with(feedback)
    end

    it "leaves swept_at NULL and logs when the card cannot be created" do
      feedback = build(:feedback)
      feedback.id = 42
      allow(FizzySweepService).to receive(:create_card).and_raise("boom")
      expect(Rails.logger).to receive(:error).with(/Feedback #42 failed to sweep into Fizzy: boom/)
      expect(feedback).not_to receive(:update!)

      feedback.sweep
    end

    it "re-raises ConfigurationError so the job can log it once" do
      feedback = build(:feedback)
      allow(FizzySweepService).to receive(:create_card).and_raise(
        FizzySweepService::ConfigurationError,
        "fizzy.api_url is not configured"
      )
      expect(feedback).not_to receive(:update!)

      expect { feedback.sweep }.to raise_error(FizzySweepService::ConfigurationError)
    end
  end
end
