require "rails_helper"

RSpec.describe GameLinkPresenter do
  let(:game) { build_stubbed(:game) }
  let(:game_link) { build_stubbed(:game_link, game: game, description: "Map", url: "https://example.com/map") }
  let(:urls) { Rails.application.routes.url_helpers }

  subject(:presenter) { described_class.new(game_link, game: game, urls: urls) }

  describe "#description" do
    it "returns the underlying description" do
      expect(presenter.description).to eq("Map")
    end
  end

  describe "#url" do
    it "returns the underlying url" do
      expect(presenter.url).to eq("https://example.com/map")
    end
  end

  describe "#edit_path" do
    it "builds the edit route for this link" do
      expect(presenter.edit_path).to eq(urls.edit_game_game_link_path(game, game_link))
    end
  end

  describe "#delete_path" do
    it "builds the delete route for this link" do
      expect(presenter.delete_path).to eq(urls.game_game_link_path(game, game_link))
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted link" do
      expect(described_class.new(GameLink.new, game: game, urls: urls).new_record?).to be(true)
    end

    it "is false for a persisted link" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#id" do
    it "returns the underlying id" do
      expect(presenter.id).to eq(game_link.id)
    end
  end

  describe "#errors?" do
    it "is false with no errors" do
      expect(presenter.errors?).to be(false)
    end

    it "is true when the link has errors" do
      game_link.errors.add(:url, "must be a valid http(s) URL")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns full error messages" do
      game_link.errors.add(:url, "must be a valid http(s) URL")
      expect(presenter.error_messages).to include("Url must be a valid http(s) URL")
    end
  end
end
