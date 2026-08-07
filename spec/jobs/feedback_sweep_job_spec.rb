require "rails_helper"

RSpec.describe FeedbackSweepJob do
  # Nulldb-safe stand-in for an ActiveRecord::Relation#find_each: yields each
  # record exactly as find_each would.
  def relation_yielding(*records)
    double("relation", find_each: nil).tap do |relation|
      allow(relation).to receive(:find_each) { |&block| records.each { |record| block.call(record) } }
    end
  end

  describe "#perform" do
    it "calls sweep on every unswept entry" do
      feedback = build(:feedback)
      other = build(:feedback)
      allow(Feedback).to receive(:unswept).and_return(relation_yielding(feedback, other))
      expect(feedback).to receive(:sweep)
      expect(other).to receive(:sweep)

      described_class.new.perform
    end

    it "logs and stops sweeping when the Fizzy credentials are missing" do
      feedback = build(:feedback)
      allow(Feedback).to receive(:unswept).and_return(relation_yielding(feedback))
      allow(feedback).to receive(:sweep).and_raise(
        FizzySweepService::ConfigurationError,
        "fizzy.api_url is not configured"
      )
      expect(Rails.logger).to receive(:error).with(/FeedbackSweepJob: fizzy.api_url is not configured/)

      expect { described_class.new.perform }.not_to raise_error

      expect(feedback).to have_received(:sweep).once
    end
  end
end
