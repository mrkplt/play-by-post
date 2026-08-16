require "rails_helper"

RSpec.describe Shared::RssFeedsSectionComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { vc_test_view_context }

  def row(token: nil)
    GameFeedRowPresenter.new(game, token: token, urls: urls)
  end

  context "when a game has no token" do
    it "renders a create-feed control for the game" do
      render_inline(described_class.new(rows: [ row ]))
      expect(page).to have_button("Create feed")
      expect(page).to have_text("Ashfall Reaches")
      expect(page).not_to have_button("Revoke")
    end
  end

  context "when a game has an rss token" do
    let(:token) { build_stubbed(:api_token, game: game, scope: "rss", token: "sekret") }

    it "renders the masked feed URL and a revoke control" do
      render_inline(described_class.new(rows: [ row(token: token) ]))
      expect(page).to have_css(".secret-field")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create feed")
    end

    it "builds the feed URL from the token value" do
      render_inline(described_class.new(rows: [ row(token: token) ]))
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="token=sekret"]))
    end
  end

  describe "#any_games?" do
    it "is false with no rows" do
      expect(described_class.new(rows: []).any_games?).to be(false)
    end

    it "is true with a row" do
      expect(described_class.new(rows: [ row ]).any_games?).to be(true)
    end
  end

  describe "#row_position" do
    it "is :last only for the final index" do
      component = described_class.new(rows: [ row, row ])
      expect(component.row_position(0)).to eq(:middle)
      expect(component.row_position(1)).to eq(:last)
    end
  end
end
