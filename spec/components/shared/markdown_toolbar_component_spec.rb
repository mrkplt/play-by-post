require "rails_helper"

RSpec.describe Shared::MarkdownToolbarComponent, type: :component do
  describe "#buttons" do
    it "exposes every formatting control keyed to a Stimulus action" do
      actions = described_class.new.buttons.map { |b| b[:action] }
      expect(actions).to eq(%w[bold italic heading quote bulletList numberList link code])
    end
  end

  describe "rendering" do
    subject(:render_toolbar) { render_inline(described_class.new) }

    it "renders a labelled toolbar" do
      render_toolbar
      expect(page).to have_css("div[role='toolbar'][aria-label='Markdown formatting']")
    end

    it "wires each button to its markdown-toolbar action as a non-submitting button" do
      render_toolbar
      described_class.new.buttons.each do |button|
        expect(page).to have_css(
          "button[type='button'][data-action='markdown-toolbar##{button[:action]}'][title='#{button[:title]}']"
        )
      end
    end

    it "labels the bold and link controls" do
      render_toolbar
      expect(page).to have_button("B")
      expect(page).to have_button("Link")
    end
  end
end
