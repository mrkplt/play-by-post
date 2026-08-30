# typed: false

require "rails_helper"

RSpec.describe Shared::AiSummariesToggleComponent, type: :component do
  let(:game) { create(:game) }

  context "when AI summaries are enabled" do
    before { game.update!(ai_summaries_enabled: true) }

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

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

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

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

  describe "presentation parameter" do
    it "rejects an unknown presentation" do
      expect do
        described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy)), presentation: :bogus)
      end.to raise_error(ArgumentError, /Unknown presentation/)
    end
  end

  context "with the default (:card) presentation" do
    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

    it "is not the row presentation" do
      expect(component.row?).to be(false)
    end

    it "renders the explanatory card copy" do
      render_inline(component)
      expect(page).to have_text("A summary is generated automatically each time a scene resolves.")
    end

    it "does not render a Ui::ToggleSwitchComponent" do
      render_inline(component)
      expect(page).not_to have_css("[role='switch']")
    end

    it "shares the stable wrapper id with the row presentation" do
      render_inline(component)
      expect(page).to have_css("#ai_summaries_toggle")
    end
  end

  context "with the :row presentation" do
    subject(:component) do
      described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy)), presentation: :row)
    end

    it "is the row presentation" do
      expect(component.row?).to be(true)
    end

    it "renders as a settings row with the AI Scene Summaries label" do
      render_inline(component)
      expect(page).to have_text("AI Scene Summaries")
      expect(page).to have_text("Auto-summarize when scenes resolve")
    end

    it "renders a Ui::ToggleSwitchComponent" do
      render_inline(component)
      expect(page).to have_css("[role='switch']")
    end

    it "does not render the explanatory card copy" do
      render_inline(component)
      expect(page).not_to have_text("A summary is generated automatically each time a scene resolves.")
    end

    it "shares the stable wrapper id with the card presentation" do
      render_inline(component)
      expect(page).to have_css("#ai_summaries_toggle")
    end

    context "when AI summaries are enabled" do
      before { game.update!(ai_summaries_enabled: true) }

      it "renders the toggle switch in the on state" do
        render_inline(component)
        expect(page).to have_css("[role='switch'][aria-checked='true']")
      end
    end

    context "when AI summaries are disabled" do
      before { game.update!(ai_summaries_enabled: false) }

      it "renders the toggle switch in the off state" do
        render_inline(component)
        expect(page).to have_css("[role='switch'][aria-checked='false']")
      end
    end
  end
end
