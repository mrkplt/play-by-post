require "rails_helper"

RSpec.describe Shared::GameControlsComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { vc_test_view_context }

  def game_row(feed_token: nil, api_token: nil, contributed: Set.new)
    GameControlRowPresenter.new(
      game, feed_token: feed_token, api_token: api_token, contributed_features: contributed, urls: urls)
  end

  def render_section(rows:, funding: false)
    render_inline(described_class.new(rows: rows, funding: funding))
  end

  context "a game card without tokens" do
    it "renders the game name with a create control per credential and no funding row" do
      render_section(rows: [ game_row ])

      expect(page).to have_text("Ashfall Reaches")
      expect(page).to have_text("RSS feed")
      expect(page).to have_text("API token")
      expect(page).to have_button("Create feed")
      expect(page).to have_button("Create token")
      expect(page).not_to have_button("Revoke")
      expect(page).not_to have_text("Fund AI")
    end

    it "posts the row's scope and the game on each create control" do
      render_section(rows: [ game_row ])

      feed_create = page.find("a", text: "Create feed")
      api_create = page.find("a", text: "Create token")
      expect(feed_create["data-turbo-method"]).to eq("post")
      expect(feed_create[:href]).to include("scope=rss")
      expect(feed_create[:href]).to include("game_id=#{game.id}")
      expect(api_create[:href]).to include("scope=api")
      expect(api_create[:href]).to include("game_id=#{game.id}")
    end
  end

  context "a game card with tokens" do
    it "reveals the feed URL and a revoke control while the api row still offers create" do
      token = build_stubbed(:api_token, game: game, scope: "rss", token: "sekret")
      render_section(rows: [ game_row(feed_token: token) ])

      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="token=sekret"]))
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create feed")
      expect(page).to have_button("Create token")
    end

    it "reveals the raw api token value" do
      token = build_stubbed(:api_token, game: game, scope: "api", token: "raw-api-token")
      render_section(rows: [ game_row(api_token: token) ])

      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="raw-api-token"]))
    end
  end

  context "the funding row" do
    let(:urls) do
      double("urls",
        game_key_contributions_path: "/create",
        game_key_contribution_path: "/destroy",
        profile_api_tokens_path: "/tokens")
    end

    it "renders a toggle per cell that posts the feature when not yet contributing" do
      render_section(rows: [ game_row ], funding: true)

      expect(page).to have_text("Fund AI")
      expect(page).to have_text("Scene summaries")
      expect(page.find("form[action='/create']")).to be_present
      expect(page).to have_css("form[action='/create'] input[name='feature'][value='scene_summary']", visible: :all)
      expect(page).not_to have_css("form[action='/create'] input[name='_method'][value='delete']", visible: :all)
    end

    it "submits DELETE when already contributing" do
      render_section(rows: [ game_row(contributed: Set.new([ "scene_summary" ])) ], funding: true)

      expect(page).to have_css("form[action='/destroy'] input[name='_method'][value='delete']", visible: :all)
    end
  end

  describe "#token_row_position" do
    it "marks the final token row :last only when no funding row follows" do
      without_funding = described_class.new(rows: [], funding: false)
      with_funding = described_class.new(rows: [], funding: true)

      expect(without_funding.token_row_position(0)).to eq(:middle)
      expect(without_funding.token_row_position(1)).to eq(:last)
      expect(with_funding.token_row_position(0)).to eq(:middle)
      expect(with_funding.token_row_position(1)).to eq(:middle)
    end
  end

  it "shows an empty-state message when the person is in no games" do
    render_section(rows: [])
    expect(page).to have_text("Join a game")
  end
end
