require "rails_helper"

RSpec.describe Shared::RssFeedsSectionComponent, type: :component do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before { create(:game_member, game: game, user: user) }

  context "when a game has no token", :db do
    it "renders a create-feed control for the game" do
      render_inline(described_class.new(user: user))
      expect(page).to have_button("Create feed")
      expect(page).to have_text(game.name)
      expect(page).not_to have_button("Revoke")
    end
  end

  context "when a game has an rss token", :db do
    before { create(:api_token, user: user, game: game, scope: "rss", token: "sekret") }

    it "renders the masked feed URL and a revoke control" do
      render_inline(described_class.new(user: user))
      expect(page).to have_css(".secret-field")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create feed")
    end

    it "builds the feed URL from the token value" do
      render_inline(described_class.new(user: user))
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value*="token=sekret"]))
    end
  end

  context "with an api-scoped token but no rss token", :db do
    before { create(:api_token, user: user, game: game, scope: "api") }

    it "still offers to create the rss feed (api scope is not a feed token)" do
      render_inline(described_class.new(user: user))
      expect(page).to have_button("Create feed")
      expect(page).not_to have_css(".secret-field")
    end
  end

  context "excludes banned memberships", :db do
    it "does not list a game the user is banned from" do
      banned_game = create(:game, name: "Forbidden Keep")
      create(:game_member, :banned, game: banned_game, user: user)
      render_inline(described_class.new(user: user))
      expect(page).not_to have_text("Forbidden Keep")
    end
  end

  describe "#any_games?", :db do
    it "is false when the user has no non-banned memberships" do
      loner = create(:user, :with_profile)
      expect(described_class.new(user: loner).any_games?).to be(false)
    end

    it "is true with a membership" do
      expect(described_class.new(user: user).any_games?).to be(true)
    end
  end
end
