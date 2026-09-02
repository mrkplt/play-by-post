require "rails_helper"

# Game::EnvironmentPage is the behaviour Game gains from its nullable
# environment_page association: the belongs-to-this-game validation and the
# environment_prompt reader that seeds portrait prompts. Exercised through Game.
RSpec.describe Game::EnvironmentPage do
  describe "#environment_prompt" do
    it "returns the designated page's body" do
      game = create(:game)
      page = create(:page, game: game, body: "A rain-soaked port city.")
      game.update!(environment_page: page)

      expect(game.environment_prompt).to eq("A rain-soaked port city.")
    end

    it "is nil when no environment page is designated" do
      expect(create(:game).environment_prompt).to be_nil
    end
  end

  describe "the belongs-to-this-game validation" do
    it "accepts a page from this game" do
      game = create(:game)
      game.environment_page = create(:page, game: game)
      expect(game).to be_valid
    end

    it "rejects a page from another game" do
      game = create(:game)
      game.environment_page = create(:page, game: create(:game))
      expect(game).not_to be_valid
      expect(game.errors[:environment_page]).to be_present
    end
  end
end
