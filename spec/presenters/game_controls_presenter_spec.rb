require "rails_helper"

RSpec.describe GameControlsPresenter do
  let(:user) { create(:user) }
  let(:urls) { double("urls") }

  def rows_for
    described_class.new(user.game_members.for_profile_listing, user: user, urls: urls).rows
  end

  it "returns one row per membership, ordered by game name" do
    create(:game_member, game: create(:game, name: "Beta"), user: user)
    create(:game_member, game: create(:game, name: "Alpha"), user: user)

    expect(rows_for.map(&:name)).to eq(%w[Alpha Beta])
  end

  it "skips a membership whose game is missing" do
    create(:game_member, game: create(:game, name: "Real"), user: user)
    ghost = build_stubbed(:game_member)
    allow(ghost).to receive(:game).and_return(nil)
    memberships = [ ghost, *user.game_members.for_profile_listing ]

    rows = described_class.new(memberships, user: user, urls: urls).rows
    expect(rows.map(&:name)).to eq([ "Real" ])
  end

  it "pairs each game with its own rss and api tokens independently" do
    with_feed = create(:game, name: "With Feed")
    with_api = create(:game, name: "With Api")
    create(:game_member, game: with_feed, user: user)
    create(:game_member, game: with_api, user: user)
    create(:api_token, user: user, game: with_feed, scope: "rss")
    create(:api_token, user: user, game: with_api, scope: "api")

    feed_row = rows_for.find { |r| r.name == "With Feed" }
    api_row = rows_for.find { |r| r.name == "With Api" }
    expect(feed_row.feed.token?).to be(true)
    expect(feed_row.api.token?).to be(false)
    expect(api_row.feed.token?).to be(false)
    expect(api_row.api.token?).to be(true)
  end

  it "marks a game's contributed features as Offered and the rest Available" do
    allow(urls).to receive(:game_key_contributions_path).and_return("/create")
    allow(urls).to receive(:game_key_contribution_path).and_return("/destroy")
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    funded = create(:game, name: "Funded")
    unfunded = create(:game, name: "Unfunded")
    create(:game_member, game: funded, user: user)
    create(:game_member, game: unfunded, user: user)
    create(:game_key_authorization, game: funded, user: user, feature: "scene_summary")

    rows = rows_for
    expect(rows.find { |r| r.name == "Funded" }.ai_cells.first).to be_a(Shared::GameControlsComponent::Offered)
    expect(rows.find { |r| r.name == "Unfunded" }.ai_cells.first).to be_a(Shared::GameControlsComponent::Available)
  end
end
