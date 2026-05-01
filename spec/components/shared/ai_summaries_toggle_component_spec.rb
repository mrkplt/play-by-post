# typed: false

require "rails_helper"

RSpec.describe Shared::AiSummariesToggleComponent, type: :component do
  let(:game) { create(:game) }

  context "when AI summaries are enabled" do
    before { game.update!(ai_summaries_enabled: true) }

    it "shows enabled status" do
      render_inline(described_class.new(game: game))
      expect(page).to have_text("enabled")
    end

    it "shows disable button label" do
      render_inline(described_class.new(game: game))
      expect(page).to have_text("Disable AI Summaries")
    end
  end

  context "when AI summaries are disabled" do
    before { game.update!(ai_summaries_enabled: false) }

    it "shows disabled status" do
      render_inline(described_class.new(game: game))
      expect(page).to have_text("disabled")
    end

    it "shows enable button label" do
      render_inline(described_class.new(game: game))
      expect(page).to have_text("Enable AI Summaries")
    end
  end
end
