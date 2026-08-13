require "rails_helper"

RSpec.describe Shared::RssFeedsSectionComponent, type: :component do
  let(:game) { instance_double(Game, id: 7, name: "Nightfall") }
  let(:membership) { instance_double(GameMember, game: game) }

  def render_component(tokens_by_game_id)
    render_inline(described_class.new(memberships: [ membership ], tokens_by_game_id: tokens_by_game_id))
  end

  context "when a game has no token" do
    it "renders a create-feed control for the game" do
      render_component({})
      expect(page).to have_button("Create feed")
      expect(page).to have_text("Nightfall")
      expect(page).not_to have_button("Revoke")
    end
  end

  context "when a game has a token" do
    let(:token) { build_stubbed(:api_token, token: "sekret") }

    it "renders the masked feed URL and a revoke control" do
      render_component({ 7 => token })
      expect(page).to have_css(".secret-field")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create feed")
    end

    it "builds the feed URL from the token value" do
      render_component({ 7 => token })
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="token=sekret"]))
    end
  end

  describe "#any_games?" do
    it "is false with no memberships" do
      component = described_class.new(memberships: [], tokens_by_game_id: {})
      expect(component.any_games?).to be(false)
    end

    it "is true with a membership" do
      component = described_class.new(memberships: [ membership ], tokens_by_game_id: {})
      expect(component.any_games?).to be(true)
    end
  end
end
