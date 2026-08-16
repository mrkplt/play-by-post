require "rails_helper"

RSpec.describe PageRoutesPresenter do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, slug: "abc123def456ghij") }

  describe "#save_draft_path" do
    it "resolves the draft autosave route for the page" do
      urls = double(save_draft_game_page_path: "/games/1/pages/2/save_draft")
      presenter = described_class.new(page_record, game: game, urls: urls)

      expect(presenter.save_draft_path).to eq("/games/1/pages/2/save_draft")
    end
  end

  describe "#publish_path" do
    it "resolves the publish route for the page" do
      urls = double(publish_game_page_path: "/games/1/pages/2/publish")
      presenter = described_class.new(page_record, game: game, urls: urls)

      expect(presenter.publish_path).to eq("/games/1/pages/2/publish")
    end
  end
end
