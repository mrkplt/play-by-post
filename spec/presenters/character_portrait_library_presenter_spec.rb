require "rails_helper"

RSpec.describe CharacterPortraitLibraryPresenter, :db do
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game) }
  # A view-context stand-in exposing exactly the URL + variant helpers the
  # presenter calls; the real controller passes the live view context. The
  # end-to-end URL correctness is covered by the request specs.
  let(:helpers) do
    double("helpers").tap do |h|
      allow(h).to receive(:url_for) { |variant| "/blob/#{variant.object_id}" }
      allow(h).to receive(:game_character_images_path).with(game, character)
        .and_return("/games/#{game.slug}/characters/#{character.id}/images")
      allow(h).to receive(:game_character_image_path) do |_g, _c, image|
        "/games/#{game.slug}/characters/#{character.id}/images/#{image.id}"
      end
    end
  end

  subject(:presenter) do
    described_class.new(character: character, game: game, can_manage: true, helpers: helpers)
  end

  describe "#items" do
    it "builds one Item per image, newest first, with URLs and the current flag" do
      older = create(:character_image, :with_file, character: character)
      newer = create(:character_image, :with_file, :current, character: character)

      items = presenter.items

      expect(items.map { |i| i[:id] }).to eq([ newer.id, older.id ])
      expect(items.first[:current]).to be(true)
      expect(items.first[:thumb_url]).to be_present
      expect(items.first[:display_url]).to be_present
    end

    it "is empty when the library is empty" do
      expect(presenter.items).to eq([])
    end

    it "points the set-current and delete URLs at the nested image route" do
      image = create(:character_image, :with_file, character: character)

      item = presenter.items.first
      expected = "/games/#{game.slug}/characters/#{character.id}/images/#{image.id}"
      expect(item[:set_current_url]).to eq(expected)
      expect(item[:delete_url]).to eq(expected)
    end
  end

  describe "#upload_url" do
    it "is the nested images collection path" do
      expect(presenter.upload_url).to eq("/games/#{game.slug}/characters/#{character.id}/images")
    end
  end

  describe "#can_manage?" do
    it "reflects the injected capability" do
      expect(presenter.can_manage?).to be(true)
      denied = described_class.new(character: character, game: game, can_manage: false, helpers: helpers)
      expect(denied.can_manage?).to be(false)
    end
  end
end
