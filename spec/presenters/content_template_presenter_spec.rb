require "rails_helper"

RSpec.describe ContentTemplatePresenter do
  let(:game) { build_stubbed(:game) }
  let(:template) { build_stubbed(:content_template, game: game, content_type: "page", body: "seed") }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(template, game: game, urls: urls) }

  describe "#content_type" do
    it "returns the raw content type" do
      expect(presenter.content_type).to eq("page")
    end
  end

  describe "#content_type_label" do
    it "capitalizes the content type" do
      expect(presenter.content_type_label).to eq("Page")
    end
  end

  describe "#body" do
    it "returns the template body" do
      expect(presenter.body).to eq("seed")
    end
  end

  describe "#available_content_types", :db do
    let(:game) { create(:game) }

    it "excludes types the game already has, keeping this template's own type" do
      create(:content_template, game: game, content_type: "note")
      persisted = create(:content_template, game: game, content_type: "page")
      presenter = described_class.new(persisted, game: game, urls: urls)

      expect(presenter.available_content_types).to contain_exactly("page", "character")
    end

    it "offers all types for a brand-new template" do
      presenter = described_class.new(game.content_templates.new, game: game, urls: urls)

      expect(presenter.available_content_types).to match_array(ContentTemplate::CONTENT_TYPES)
    end
  end

  describe "#new_record?" do
    it "is true for an unsaved template" do
      presenter = described_class.new(ContentTemplate.new, game: game, urls: urls)
      expect(presenter.new_record?).to be(true)
    end

    it "is false for a persisted template" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#errors? and #error_messages" do
    it "surface the model's validation errors" do
      invalid = ContentTemplate.new
      invalid.valid?
      presenter = described_class.new(invalid, game: game, urls: urls)

      expect(presenter.errors?).to be(true)
      expect(presenter.error_messages).to include(a_string_matching(/Body/i))
    end

    it "reports no errors on a clean template" do
      expect(presenter.errors?).to be(false)
      expect(presenter.error_messages).to eq([])
    end
  end

  describe "#edit_path" do
    it "resolves the edit route" do
      allow(urls).to receive(:edit_game_content_template_path).with(game, template).and_return("/edit")
      expect(presenter.edit_path).to eq("/edit")
    end
  end

  describe "#list_row_attributes" do
    it "pairs the content-type label with the edit href for a list row" do
      allow(urls).to receive(:edit_game_content_template_path).with(game, template).and_return("/edit")
      expect(presenter.list_row_attributes).to eq(title: "Page", href: "/edit")
    end
  end

  describe "#delete_path" do
    it "resolves the resource route" do
      allow(urls).to receive(:game_content_template_path).with(game, template).and_return("/template")
      expect(presenter.delete_path).to eq("/template")
    end
  end
end
