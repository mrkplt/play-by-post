require "rails_helper"

RSpec.describe Shared::TokenSectionComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { vc_test_view_context }

  def feed_row(token: nil)
    GameFeedRowPresenter.new(game, token: token, urls: urls)
  end

  def api_row(token: nil)
    ApiTokenRowPresenter.new(game, token: token, urls: urls)
  end

  def render_section(rows:, scope:, secret_label:, create_label:)
    render_inline(described_class.new(rows: rows, scope: scope, secret_label: secret_label, create_label: create_label))
  end

  context "the RSS-feed configuration" do
    let(:token) { build_stubbed(:api_token, game: game, scope: "rss", token: "sekret") }

    it "renders a create-feed control when there is no token" do
      render_section(rows: [ feed_row ], scope: "rss", secret_label: "Feed URL", create_label: "Create feed")
      expect(page).to have_button("Create feed")
      expect(page).to have_text("Ashfall Reaches")
      expect(page).not_to have_button("Revoke")
    end

    it "reveals the feed URL (built from the token) and a revoke control when a token exists" do
      render_section(rows: [ feed_row(token: token) ], scope: "rss", secret_label: "Feed URL", create_label: "Create feed")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create feed")
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="token=sekret"]))
    end

    it "posts scope rss on the create control" do
      render_section(rows: [ feed_row ], scope: "rss", secret_label: "Feed URL", create_label: "Create feed")
      expect(page).to have_css(%(input[name="scope"][value="rss"]), visible: :all)
    end
  end

  context "the API-token configuration" do
    let(:token) { build_stubbed(:api_token, game: game, scope: "api", token: "raw-api-token") }

    it "renders a create-token control when there is no token" do
      render_section(rows: [ api_row ], scope: "api", secret_label: "API token", create_label: "Create token")
      expect(page).to have_button("Create token")
      expect(page).not_to have_button("Revoke")
    end

    it "reveals the raw token value and posts scope api on create" do
      render_section(rows: [ api_row(token: token) ], scope: "api", secret_label: "API token", create_label: "Create token")
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="raw-api-token"]))
      expect(page).to have_button("Revoke")
    end
  end

  describe "#row_position" do
    it "is :last only for the final index" do
      component = described_class.new(rows: [ feed_row, feed_row ], scope: "rss", secret_label: "x", create_label: "y")
      expect(component.row_position(0)).to eq(:middle)
      expect(component.row_position(1)).to eq(:last)
    end
  end
end
