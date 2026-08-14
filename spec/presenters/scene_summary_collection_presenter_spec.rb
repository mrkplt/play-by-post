require "rails_helper"

RSpec.describe SceneSummaryCollectionPresenter do
  let(:game) { build_stubbed(:game) }
  let(:urls) { double("urls") }
  let(:pagy) { double("Pagy", series_nav: "<nav>...</nav>") }

  describe "#empty?" do
    it "is true when there are no summaries" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.empty?).to be(true)
    end

    it "is false when there are summaries" do
      summary = build_stubbed(:scene_summary)
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)
      expect(presenter.empty?).to be(false)
    end
  end

  describe "#entries" do
    it "wraps each summary in a SceneSummaryPresenter carrying the injected game and url_helpers" do
      summary = build_stubbed(:scene_summary)
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)

      entries = presenter.entries
      expect(entries.length).to eq(1)
      expect(entries.first).to be_a(SceneSummaryPresenter)
      expect(entries.first.__getobj__).to eq(summary)
    end

    it "is empty when there are no summaries" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.entries).to eq([])
    end
  end

  describe "#pagy_nav" do
    it "delegates to the injected pagy object's series_nav" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.pagy_nav).to eq("<nav>...</nav>")
    end
  end
end
