require "rails_helper"

RSpec.describe ApiTokenRowsBuilder do
  let(:user) { create(:user) }
  let(:urls) { double("urls") }

  it "returns one row per non-banned membership, paired with any api token, ordered by game name" do
    beta = create(:game, name: "Beta")
    alpha = create(:game, name: "Alpha")
    create(:game_member, game: beta, user: user)
    create(:game_member, game: alpha, user: user)
    token = create(:api_token, user: user, game: alpha, scope: "api")

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.map(&:name)).to eq(%w[Alpha Beta])
    expect(rows.find { |r| r.game_id == alpha.id }.token_value).to eq(token.token)
    expect(rows.find { |r| r.game_id == beta.id }.token?).to be(false)
  end

  it "excludes banned memberships" do
    banned = create(:game, name: "Forbidden Keep")
    create(:game_member, :banned, game: banned, user: user)

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.map(&:game_id)).not_to include(banned.id)
  end

  it "ignores an rss-scoped token when matching the api token" do
    game = create(:game)
    create(:game_member, game: game, user: user)
    create(:api_token, user: user, game: game, scope: "rss")

    rows = described_class.new(user: user, urls: urls).rows

    expect(rows.first.token?).to be(false)
  end
end
