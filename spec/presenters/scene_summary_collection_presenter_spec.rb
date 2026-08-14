require "rails_helper"

RSpec.describe SceneSummaryCollectionPresenter do
  let(:pagy) { double("Pagy") }

  describe "#empty?" do
    it "is true when the relation is empty" do
      presenter = described_class.new(SceneSummary.none, pagy: pagy)
      expect(presenter.empty?).to be(true)
    end

    it "is false when the relation has rows", :db do
      create(:scene_summary)
      presenter = described_class.new(SceneSummary.all, pagy: pagy)
      expect(presenter.empty?).to be(false)
    end
  end

  describe "#summaries" do
    it "wraps each summary in a SceneSummaryPresenter, preserving order", :db do
      summary_1 = create(:scene_summary)
      summary_2 = create(:scene_summary)
      presenter = described_class.new(SceneSummary.where(id: [ summary_1.id, summary_2.id ]).order(:id), pagy: pagy)

      expect(presenter.summaries).to all(be_a(SceneSummaryPresenter))
      expect(presenter.summaries.map(&:__getobj__)).to eq([ summary_1, summary_2 ])
    end
  end

  describe "#pagy" do
    it "returns the injected pagy object" do
      presenter = described_class.new(SceneSummary.none, pagy: pagy)
      expect(presenter.pagy).to eq(pagy)
    end

    it "raises when pagy was not supplied" do
      presenter = described_class.new(SceneSummary.none)
      expect { presenter.pagy }.to raise_error(KeyError)
    end
  end
end
