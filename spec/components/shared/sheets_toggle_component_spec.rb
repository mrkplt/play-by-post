# typed: false

require "rails_helper"

RSpec.describe Shared::SheetsToggleComponent, type: :component do
  let(:game) { create(:game) }

  context "when sheets are hidden" do
    before { game.update!(sheets_hidden: true) }

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

    it "hidden? returns true" do
      expect(component.hidden?).to be(true)
    end

    it "toggle_label returns 'Show Character Sheets'" do
      expect(component.toggle_label).to eq("Show Character Sheets")
    end

    it "shows the show button label" do
      render_inline(component)
      expect(page).to have_text("Show Character Sheets")
    end
  end

  context "when sheets are visible" do
    before { game.update!(sheets_hidden: false) }

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

    it "hidden? returns false" do
      expect(component.hidden?).to be(false)
    end

    it "toggle_label returns 'Hide Character Sheets'" do
      expect(component.toggle_label).to eq("Hide Character Sheets")
    end

    it "shows the hide button label" do
      render_inline(component)
      expect(page).to have_text("Hide Character Sheets")
    end
  end
end
