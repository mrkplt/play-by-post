require "rails_helper"
require "csv"

RSpec.describe GameExport::AuditDocument do
  let(:names) { { 1 => "Requester Jo", 2 => "Funder Al" } }

  def generation(**overrides)
    build_stubbed(
      :ai_generation,
      {
        created_at: Time.utc(2026, 5, 6, 14, 30),
        feature: "scene_summary", asset_type: "SceneSummary", asset_id: 42,
        model_used: "openai/gpt-4o", requested_by_id: 1, funded_by_id: 2,
        input_tokens: 500, output_tokens: 150, cost: 0.0123
      }.merge(overrides)
    )
  end

  def rows(csv)
    CSV.parse(csv)
  end

  describe ".csv" do
    it "writes the header row even with no generations" do
      expect(rows(described_class.csv([], names))).to eq([ described_class::HEADERS ])
    end

    it "writes one row per generation, resolving names and formatting the timestamp" do
      csv = described_class.csv([ generation ], names)
      header, row = rows(csv)

      expect(header).to eq(described_class::HEADERS)
      expect(row).to eq([
        "2026-05-06T14:30:00Z", "scene_summary", "SceneSummary#42", "openai/gpt-4o",
        "Requester Jo", "Funder Al", "500", "150", "0.0123"
      ])
    end

    it "leaves the name cell blank when a user is no longer resolvable" do
      csv = described_class.csv([ generation(requested_by_id: 999) ], names)
      _header, row = rows(csv)

      expect(row[4]).to be_nil.or eq("")
    end

    it "leaves token and cost cells blank when they were not recorded" do
      csv = described_class.csv([ generation(input_tokens: nil, output_tokens: nil, cost: nil) ], names)
      _header, row = rows(csv)

      expect(row[6]).to be_nil.or eq("")
      expect(row[8]).to be_nil.or eq("")
    end
  end
end
