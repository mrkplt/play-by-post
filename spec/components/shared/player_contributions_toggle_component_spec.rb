# typed: false

require "rails_helper"

RSpec.describe Shared::PlayerContributionsToggleComponent, type: :component do
  let(:game) { create(:game) }

  subject(:component) { described_class.new(game: GamePresenter.new(game, policy: instance_double(GamePolicy))) }

  context "when player contributions are enabled" do
    before { game.update!(player_contributions_enabled: true) }

    it "enabled? returns true" do
      expect(component.enabled?).to be(true)
    end

    it "status_text reads 'enabled'" do
      expect(component.status_text).to eq("enabled")
    end

    it "toggle_label offers to disable" do
      expect(component.toggle_label).to eq("Disable Player Contributions")
    end

    it "renders the current status and the disable action" do
      render_inline(component)
      expect(page).to have_text("enabled")
      expect(page).to have_button("Disable Player Contributions")
    end
  end

  context "when player contributions are disabled" do
    before { game.update!(player_contributions_enabled: false) }

    it "enabled? returns false" do
      expect(component.enabled?).to be(false)
    end

    it "status_text reads 'disabled'" do
      expect(component.status_text).to eq("disabled")
    end

    it "toggle_label offers to enable" do
      expect(component.toggle_label).to eq("Enable Player Contributions")
    end

    it "renders the enable action" do
      render_inline(component)
      expect(page).to have_button("Enable Player Contributions")
    end
  end
end
