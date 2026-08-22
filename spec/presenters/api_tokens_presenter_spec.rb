require "rails_helper"

RSpec.describe ApiTokensPresenter do
  let(:user) { create(:user) }
  let(:urls) { double("urls") }

  def rows_for
    described_class.new(user.game_members.for_profile_listing, user: user, urls: urls).rows
  end

  it "returns one row per membership, paired with any api token, ordered by game name" do
    beta = create(:game, name: "Beta")
    alpha = create(:game, name: "Alpha")
    create(:game_member, game: beta, user: user)
    create(:game_member, game: alpha, user: user)
    token = create(:api_token, user: user, game: alpha, scope: "api")

    rows = rows_for
    expect(rows.map(&:name)).to eq(%w[Alpha Beta])
    expect(rows.find { |r| r.game_id == alpha.id }.token_value).to eq(token.token)
    expect(rows.find { |r| r.game_id == beta.id }.token?).to be(false)
  end

  it "ignores an rss-scoped token when matching the api token" do
    game = create(:game)
    create(:game_member, game: game, user: user)
    create(:api_token, user: user, game: game, scope: "rss")

    expect(rows_for.first.token?).to be(false)
  end
end
