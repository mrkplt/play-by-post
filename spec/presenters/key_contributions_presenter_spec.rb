require "rails_helper"

RSpec.describe KeyContributionsPresenter do
  let(:user) { create(:user) }
  let(:urls) { double("urls") }

  before do
    allow(urls).to receive(:game_key_contributions_path).and_return("/create")
    allow(urls).to receive(:game_key_contribution_path).and_return("/destroy")
  end

  def rows_for
    described_class.new(user.game_members.for_profile_listing, user: user, urls: urls).rows
  end

  it "returns one row per membership, ordered by game name" do
    create(:game_member, game: create(:game, name: "Beta"), user: user)
    create(:game_member, game: create(:game, name: "Alpha"), user: user)

    expect(rows_for.map(&:name)).to eq(%w[Alpha Beta])
  end

  it "marks a game's contributed features as Offered and the rest Available" do
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    funded = create(:game, name: "Funded")
    unfunded = create(:game, name: "Unfunded")
    create(:game_member, game: funded, user: user)
    create(:game_member, game: unfunded, user: user)
    create(:game_key_authorization, game: funded, user: user, feature: "scene_summary")

    rows = rows_for
    expect(rows.find { |r| r.name == "Funded" }.cells.first).to be_a(Shared::KeyContributionMatrixComponent::Offered)
    expect(rows.find { |r| r.name == "Unfunded" }.cells.first).to be_a(Shared::KeyContributionMatrixComponent::Available)
  end
end
