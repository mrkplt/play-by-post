# typed: false

require "rails_helper"

RSpec.describe Shared::ImagesToggleComponent, type: :component do
  let(:game) { create(:game) }

  context "when images are disabled" do
    before { game.update!(images_disabled: true) }

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

    it "disabled? returns true" do
      expect(component.disabled?).to be(true)
    end

    it "toggle_label returns 'Enable'" do
      expect(component.toggle_label).to eq("Enable")
    end

    it "shows the enable button label" do
      render_inline(component)
      expect(page).to have_text("Enable")
    end
  end

  context "when images are enabled" do
    before { game.update!(images_disabled: false) }

    subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

    it "disabled? returns false" do
      expect(component.disabled?).to be(false)
    end

    it "toggle_label returns 'Disable'" do
      expect(component.toggle_label).to eq("Disable")
    end

    it "shows the disable button label" do
      render_inline(component)
      expect(page).to have_text("Disable")
    end
  end
end
