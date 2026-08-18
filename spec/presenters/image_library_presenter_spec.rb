require "rails_helper"

# ImageLibraryPresenter's concrete behaviour (items / item_for / initialize /
# can_manage? / upload_url) lives on the base and is exercised through a
# concrete adopter, CharacterPortraitLibraryPresenter. Described as
# ImageLibraryPresenter so mutant attributes these examples to the base subject
# (the same technique the Versionable::Model / UploadedImage::Model specs use).
# The abstract hooks (images / set_current_url / delete_url) are the subclass's
# to implement and are covered in the subclass specs.
RSpec.describe ImageLibraryPresenter, :db do
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game) }
  # url_for returns a stable, transformation-tagged URL so the two variants
  # (thumbnail vs display) get distinct, assertable URLs — a mutant swapping
  # thumbnail_variant/display_variant is then caught.
  let(:helpers) do
    double("helpers").tap do |h|
      allow(h).to receive(:url_for) do |variant|
        "/blob/#{variant.variation.transformations[:resize_to_fill].first}"
      end
      allow(h).to receive(:game_character_images_path).with(game, character)
        .and_return("/upload/url")
      allow(h).to receive(:game_character_image_path).with(game, character, anything) do |_g, _c, image|
        "/member/#{image.id}"
      end
    end
  end

  # A concrete adopter so the base's methods run end to end.
  subject(:presenter) do
    CharacterPortraitLibraryPresenter.new(character: character, game: game, can_manage: true, helpers: helpers)
  end

  describe "#items / #item_for" do
    it "maps each image to a fully-populated Item hash" do
      image = create(:character_image, :with_file, :current, character: character)

      item = presenter.items.first

      expect(item).to eq(
        id: image.id,
        thumb_url: "/blob/96",     # 96px thumbnail_variant
        display_url: "/blob/512",  # 512px display_variant
        current: true,
        set_current_url: "/member/#{image.id}",
        delete_url: "/member/#{image.id}"
      )
    end

    it "reports the current flag as false for a non-current image" do
      create(:character_image, :with_file, character: character)

      expect(presenter.items.first[:current]).to be(false)
    end

    it "returns one Item per image" do
      create(:character_image, :with_file, character: character)
      create(:character_image, :with_file, character: character)

      expect(presenter.items.size).to eq(2)
    end

    it "is empty when there are no images" do
      expect(presenter.items).to eq([])
    end
  end

  describe "#can_manage?" do
    it "is true when the adopter grants management" do
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the adopter denies management" do
      denied = CharacterPortraitLibraryPresenter.new(
        character: character, game: game, can_manage: false, helpers: helpers
      )
      expect(denied.can_manage?).to be(false)
    end
  end

  describe "#upload_url" do
    it "delegates to the adopter's collection route" do
      expect(presenter.upload_url).to eq("/upload/url")
    end
  end
end
