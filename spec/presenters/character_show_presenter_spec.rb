require "rails_helper"

RSpec.describe CharacterShowPresenter do
  let(:game) { build_stubbed(:game) }
  let(:character) { build_stubbed(:character, game: game) }

  subject(:presenter) { described_class.new(character) }

  describe "#owner" do
    it "wraps the character's user as a UserPresenter" do
      result = presenter.owner
      expect(result).to be_a(UserPresenter)
      expect(result.__getobj__).to eq(character.user)
    end
  end

  describe "#versions" do
    it "returns each character version, newest first, wrapped as presenters" do
      version = build_stubbed(:character_version)
      versions_rel = double("versions rel")
      ordered_rel = double("ordered rel")
      allow(character).to receive(:character_versions).and_return(versions_rel)
      allow(versions_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:includes).with(:edited_by).and_return([ version ])

      result = presenter.versions
      expect(result).to all(be_a(CharacterVersionPresenter))
      expect(result.map(&:__getobj__)).to eq([ version ])
    end
  end

  describe "portrait library", :db do
    let(:game) { create(:game) }
    let(:character) { create(:character, game: game) }
    let(:helpers) do
      double("helpers").tap do |h|
        allow(h).to receive(:url_for) { |variant| "/blob/#{variant.object_id}" }
        allow(h).to receive(:game_character_images_path)
          .and_return("/games/#{game.slug}/characters/#{character.id}/images")
        allow(h).to receive(:game_character_image_path) do |_g, _c, image|
          "/games/#{game.slug}/characters/#{character.id}/images/#{image.id}"
        end
      end
    end

    subject(:presenter) do
      described_class.new(character, game: game, can_manage_portraits: true, helpers: helpers)
    end

    it "#portrait_items exposes the library's items" do
      create(:character_image, :with_file, :current, character: character)
      expect(presenter.portrait_items.map { |i| i[:current] }).to eq([ true ])
    end

    it "#can_manage_portraits? reflects the injected capability" do
      expect(presenter.can_manage_portraits?).to be(true)
    end

    it "#portrait_upload_url is the nested images path" do
      expect(presenter.portrait_upload_url).to eq("/games/#{game.slug}/characters/#{character.id}/images")
    end
  end
end
