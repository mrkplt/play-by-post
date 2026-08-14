require "rails_helper"

RSpec.describe Shared::DeleteGameComponent, type: :component do
  let(:game_model) { build_stubbed(:game, name: "Curse of Strahd") }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }
  subject(:component) { described_class.new(game: game) }

  describe "helper methods" do
    it "exposes the game name" do
      expect(component.game_name).to eq("Curse of Strahd")
    end

    it "instructs the GM to type the game name, quoted" do
      expect(component.confirm_instruction).to eq(%(Type "Curse of Strahd" to confirm))
    end

    it "quotes the game name in the heading" do
      expect(component.delete_heading).to eq(%(Delete "Curse of Strahd"?))
    end
  end

  describe "rendering" do
    # The modal starts hidden, so its contents are inspected with visible: :all.
    before { render_inline(component) }

    it "renders a button that opens the confirmation modal" do
      expect(page).to have_css("button[data-action='click->game-delete#open']", text: "Delete Game")
    end

    it "names the game in the confirmation modal" do
      expect(page).to have_css("[data-testid='delete-game-modal']", visible: :all)
      expect(page).to have_css("h2", text: %(Delete "Curse of Strahd"?), visible: :all)
      expect(page).to have_text(%(Type "Curse of Strahd" to confirm), normalize_ws: true)
    end

    it "wires the modal to the game name so the submit can be gated client-side" do
      expect(page).to have_css("[data-game-delete-name-value='Curse of Strahd']")
      expect(page).to have_css("input[data-game-delete-target='input']", visible: :all)
    end

    it "renders the destructive submit disabled, targeting the delete route" do
      submit = page.find("button[data-game-delete-target='submit']", visible: :all)
      expect(submit).to be_disabled
      form = page.find("form[action='/games/#{game_model.id}']", visible: :all)
      expect(form).to have_css("input[name='_method'][value='delete']", visible: :all)
    end
  end
end
