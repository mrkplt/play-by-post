require "rails_helper"

RSpec.describe FeedbackSweepJob do
  let(:feedback) { build(:feedback) }
  let(:service) { instance_double(FizzySweepService) }

  # Nulldb-safe stand-in for an ActiveRecord::Relation#find_each: yields each
  # record exactly as find_each would.
  def relation_yielding(*records)
    double("relation", find_each: nil).tap do |relation|
      allow(relation).to receive(:find_each) { |&block| records.each { |record| block.call(record) } }
    end
  end

  def stub_service(result: true)
    allow(FizzySweepService).to receive(:new).and_return(service)
    if result.is_a?(Exception)
      allow(service).to receive(:create_card).and_raise(result)
    else
      allow(service).to receive(:create_card).and_return(nil)
    end
  end

  describe "#perform" do
    it "stamps swept_at on every entry it sweeps" do
      job = described_class.new
      allow(job).to receive(:unswept).and_return(relation_yielding(feedback))
      stub_service
      expect(feedback).to receive(:update!).with(swept_at: instance_of(ActiveSupport::TimeWithZone))

      job.perform

      expect(service).to have_received(:create_card).with(feedback)
    end

    it "leaves swept_at NULL and continues when one entry fails" do
      other = build(:feedback)
      job = described_class.new
      allow(job).to receive(:unswept).and_return(relation_yielding(feedback, other))
      allow(FizzySweepService).to receive(:new).and_return(service)
      allow(service).to receive(:create_card).with(feedback).and_raise("boom")
      allow(service).to receive(:create_card).with(other).and_return(nil)
      expect(other).to receive(:update!).with(swept_at: instance_of(ActiveSupport::TimeWithZone))
      allow(Rails.logger).to receive(:error)

      job.perform

      expect(service).to have_received(:create_card).with(feedback)
      expect(service).to have_received(:create_card).with(other)
    end

    it "logs and stops sweeping when the Fizzy credentials are missing" do
      job = described_class.new
      allow(job).to receive(:unswept).and_return(relation_yielding(feedback, build(:feedback)))
      stub_service(result: FizzySweepService::ConfigurationError.new("fizzy.api_url is not configured"))
      expect(Rails.logger).to receive(:error).with(/FeedbackSweepJob: fizzy.api_url is not configured/)

      expect { job.perform }.not_to raise_error

      expect(service).to have_received(:create_card).with(feedback).once
    end

    it "selects only entries that have not been swept" do
      sql = unquoted_sql(described_class.new.unswept)

      expect(sql).to include("feedback.swept_at IS NULL")
    end
  end
end
