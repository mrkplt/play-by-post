require "rails_helper"

RSpec.describe KeyContributionRowPresenter do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { double("urls") }

  before do
    allow(urls).to receive(:game_key_contributions_path).with(game).and_return("/create")
    allow(urls).to receive(:game_key_contribution_path).with(game, "scene_summary").and_return("/destroy/scene_summary")
  end

  describe "#name" do
    it "delegates to the game" do
      presenter = described_class.new(game, contributed_features: Set.new, urls: urls)
      expect(presenter.name).to eq("Ashfall Reaches")
    end
  end

  describe "#cells" do
    it "returns one cell per pool-fundable feature" do
      presenter = described_class.new(game, contributed_features: Set.new, urls: urls)
      expect(presenter.cells.map(&:label)).to eq([ "Scene summaries" ])
    end

    it "builds an Offered (DELETE, no params) cell at the destroy path when funded" do
      presenter = described_class.new(game, contributed_features: Set.new([ "scene_summary" ]), urls: urls)
      cell = presenter.cells.first

      expect(cell).to be_a(KeyContributionRowPresenter::Offered)
      expect(cell.http_method).to eq(:delete)
      expect(cell.params).to eq({})
      expect(cell.switch_state).to eq(:on)
      expect(cell.path).to eq("/destroy/scene_summary")
      expect(cell.aria_label).to eq("Stop funding Scene summaries with your key")
    end

    it "builds an Available (POST, feature param) cell at the create path when not funded" do
      presenter = described_class.new(game, contributed_features: Set.new, urls: urls)
      cell = presenter.cells.first

      expect(cell).to be_a(KeyContributionRowPresenter::Available)
      expect(cell.http_method).to eq(:post)
      expect(cell.params).to eq({ feature: "scene_summary" })
      expect(cell.switch_state).to eq(:off)
      expect(cell.path).to eq("/create")
      expect(cell.aria_label).to eq("Fund Scene summaries with your key")
    end
  end
end
