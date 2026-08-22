require "rails_helper"

RSpec.describe KeyContributionRowsBuilder do
  let(:user) { create(:user) }
  let(:urls) { double("urls") }

  before do
    allow(urls).to receive(:game_key_contributions_path).and_return("/create")
    allow(urls).to receive(:game_key_contribution_path).and_return("/destroy")
  end

  it "returns one row per non-banned membership, ordered by game name" do
    beta = create(:game, name: "Beta")
    alpha = create(:game, name: "Alpha")
    create(:game_member, game: beta, user: user)
    create(:game_member, game: alpha, user: user)

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.map(&:name)).to eq(%w[Alpha Beta])
  end

  it "excludes banned memberships" do
    banned = create(:game, name: "Forbidden")
    create(:game_member, :banned, game: banned, user: user)

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.map(&:name)).not_to include("Forbidden")
  end

  it "marks a game's contributed features as Offered" do
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    game = create(:game, name: "Funded")
    create(:game_member, game: game, user: user)
    create(:game_key_authorization, game: game, user: user, feature: "scene_summary")

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.first.cells.first).to be_a(Shared::KeyContributionMatrixComponent::Offered)
  end
end
