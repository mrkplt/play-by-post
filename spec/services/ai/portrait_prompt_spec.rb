require "rails_helper"

# Ai::PortraitPrompt composes safety preamble + GM environment part + player
# part, and exposes the two source parts for the refusal logger.
RSpec.describe Ai::PortraitPrompt do
  let(:game) { create(:game) }

  def prompt_for(player_prompt, env_body: nil)
    if env_body
      game.update!(environment_page: create(:page, game: game, body: env_body))
    end
    described_class.new(game: game, player_prompt: player_prompt)
  end

  describe "#to_s" do
    it "always begins with the safety preamble" do
      composed = prompt_for("a grizzled dwarven smith").to_s
      expect(composed).to start_with(Ai::PortraitSafetyPrompt.text)
    end

    it "includes the environment part when the game designates one" do
      composed = prompt_for("a smith", env_body: "The ashfall wastes.").to_s
      expect(composed).to include("The ashfall wastes.")
      expect(composed).to include("a smith")
    end

    it "omits the environment part (and does not crash) when none is designated" do
      composed = prompt_for("a smith").to_s
      expect(composed).to eq("#{Ai::PortraitSafetyPrompt.text}\n\na smith")
    end

    it "omits an environment part whose body is blank" do
      composed = prompt_for("a smith", env_body: "   ").to_s
      expect(composed).to eq("#{Ai::PortraitSafetyPrompt.text}\n\na smith")
    end

    it "orders safety, then environment, then player" do
      composed = prompt_for("PLAYER_TEXT", env_body: "ENV_TEXT").to_s
      expect(composed.index("ENV_TEXT")).to be < composed.index("PLAYER_TEXT")
      expect(composed.index(Ai::PortraitSafetyPrompt.text)).to be < composed.index("ENV_TEXT")
    end
  end

  describe "#game_part / #player_part" do
    it "exposes the stripped environment body" do
      expect(prompt_for("x", env_body: "  ENV  ").game_part).to eq("ENV")
    end

    it "is nil for game_part when no environment page" do
      expect(prompt_for("x").game_part).to be_nil
    end

    it "exposes the stripped player prompt" do
      expect(prompt_for("  hi  ").player_part).to eq("hi")
    end
  end
end
