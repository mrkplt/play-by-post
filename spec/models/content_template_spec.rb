require "rails_helper"

RSpec.describe ContentTemplate do
  describe "associations" do
    it "belongs to a game" do
      expect(described_class.reflect_on_association(:game).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires a body" do
      template = build(:content_template, body: "")
      expect(template).not_to be_valid
      expect(template.errors[:body]).to be_present
    end

    it "requires a content_type" do
      template = build(:content_template, content_type: nil)
      expect(template).not_to be_valid
      expect(template.errors[:content_type]).to be_present
    end

    it "rejects a content_type outside the allowed set" do
      template = build(:content_template, content_type: "spaceship")
      expect(template).not_to be_valid
      expect(template.errors[:content_type]).to be_present
    end

    it "accepts each allowed content_type" do
      ContentTemplate::CONTENT_TYPES.each do |type|
        expect(build(:content_template, content_type: type)).to be_valid
      end
    end

    it "enforces one template per (game, content_type)", :db do
      game = create(:game)
      create(:content_template, game: game, content_type: "page")
      duplicate = build(:content_template, game: game, content_type: "page")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:content_type]).to be_present
    end

    it "allows the same content_type across different games", :db do
      create(:content_template, game: create(:game), content_type: "page")
      other = build(:content_template, game: create(:game), content_type: "page")

      expect(other).to be_valid
    end
  end

  describe ".body_for", :db do
    let(:game) { create(:game) }

    it "returns the template body for the game and type" do
      create(:content_template, game: game, content_type: "page", body: "seed me")

      expect(described_class.body_for(game: game, content_type: "page")).to eq("seed me")
    end

    it "is nil when the game has no template of that type" do
      expect(described_class.body_for(game: game, content_type: "page")).to be_nil
    end

    it "is scoped to the game — another game's template does not leak" do
      create(:content_template, game: create(:game), content_type: "page", body: "other game")

      expect(described_class.body_for(game: game, content_type: "page")).to be_nil
    end

    it "is scoped to the content_type — a different type does not match" do
      create(:content_template, game: game, content_type: "note", body: "a note")

      expect(described_class.body_for(game: game, content_type: "page")).to be_nil
    end
  end
end
