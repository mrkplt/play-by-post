# typed: false

require "rails_helper"

RSpec.describe Shared::AiSummariesToggleComponent, type: :component do
  let(:game) { create(:game) }

  context "when AI summaries are enabled" do
    before { game.update!(ai_summaries_enabled: true) }

    subject(:component) { described_class.new(game: game) }

    it "status_text returns 'enabled'" do
      expect(component.status_text).to eq("enabled")
    end

    it "toggle_label returns 'Disable AI Summaries'" do
      expect(component.toggle_label).to eq("Disable AI Summaries")
    end

    it "enabled? returns true" do
      expect(component.enabled?).to be(true)
    end

    it "shows enabled status in bold" do
      render_inline(component)
      expect(page).to have_css("strong", text: "enabled")
    end

    it "shows disable button label" do
      render_inline(component)
      expect(page).to have_text("Disable AI Summaries")
    end
  end

  context "when AI summaries are disabled" do
    before { game.update!(ai_summaries_enabled: false) }

    subject(:component) { described_class.new(game: game) }

    it "status_text returns 'disabled'" do
      expect(component.status_text).to eq("disabled")
    end

    it "toggle_label returns 'Enable AI Summaries'" do
      expect(component.toggle_label).to eq("Enable AI Summaries")
    end

    it "enabled? returns false" do
      expect(component.enabled?).to be(false)
    end

    it "shows disabled status in bold" do
      render_inline(component)
      expect(page).to have_css("strong", text: "disabled")
    end

    it "shows enable button label" do
      render_inline(component)
      expect(page).to have_text("Enable AI Summaries")
    end
  end
end
