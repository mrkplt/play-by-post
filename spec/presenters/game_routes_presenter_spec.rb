require "rails_helper"

RSpec.describe GameRoutesPresenter do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:urls) { double("url_helpers") }

  subject(:presenter) { described_class.new(game_presenter, urls: urls) }

  describe "#new_scene_path" do
    it "builds the new-scene path from the injected url_helpers" do
      allow(urls).to receive(:new_game_scene_path).with(game).and_return("/games/#{game.id}/scenes/new")
      expect(presenter.new_scene_path).to eq("/games/#{game.id}/scenes/new")
    end
  end

  describe "#edit_path" do
    it "builds the game's edit path from the injected url_helpers" do
      allow(urls).to receive(:edit_game_path).with(game).and_return("/games/#{game.id}/edit")
      expect(presenter.edit_path).to eq("/games/#{game.id}/edit")
    end
  end

  describe "#notebook_board_href" do
    it "resolves the game's Campaign Notebook board URL" do
      allow(urls).to receive(:game_notebook_entries_path).with(game).and_return("/games/1/notebook_entries")
      expect(presenter.notebook_board_href).to eq("/games/1/notebook_entries")
    end
  end
end
