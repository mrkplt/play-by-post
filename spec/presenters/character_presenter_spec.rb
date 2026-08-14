require "rails_helper"

RSpec.describe CharacterPresenter do
  let(:game) { build_stubbed(:game) }
  let(:character) { build_stubbed(:character, game: game, name: "Thornwall", content: "Sheet content") }
  let(:character_policy) { instance_double(CharacterPolicy, update?: true, assign_owner?: true) }
  let(:urls) { double("urls") }

  subject(:presenter) do
    described_class.new(character, character_policy: character_policy, urls: urls)
  end

  describe "#can_edit?" do
    it "is true when the injected character policy allows update" do
      allow(character_policy).to receive(:update?).and_return(true)
      expect(presenter.can_edit?).to be(true)
    end

    it "is false when the injected character policy disallows update" do
      allow(character_policy).to receive(:update?).and_return(false)
      expect(presenter.can_edit?).to be(false)
    end
  end

  describe "#can_assign_owner?" do
    it "is true when the injected character policy allows assigning the owner" do
      allow(character_policy).to receive(:assign_owner?).and_return(true)
      expect(presenter.can_assign_owner?).to be(true)
    end

    it "is false when the injected character policy disallows assigning the owner" do
      allow(character_policy).to receive(:assign_owner?).and_return(false)
      expect(presenter.can_assign_owner?).to be(false)
    end
  end

  describe "#game" do
    it "returns the character's game" do
      expect(presenter.game).to eq(game)
    end
  end

  describe "#edit_href" do
    it "resolves this character's edit URL" do
      allow(urls).to receive(:edit_game_character_path).with(game, character).and_return("/games/1/characters/2/edit")
      expect(presenter.edit_href).to eq("/games/1/characters/2/edit")
    end
  end

  describe "#cancel_href" do
    it "returns the game's URL for an unsaved character" do
      new_character = game.characters.new
      allow(urls).to receive(:game_path).with(game).and_return("/games/1")
      presenter = described_class.new(new_character, character_policy: character_policy, urls: urls)

      expect(presenter.cancel_href).to eq("/games/1")
    end

    it "returns the character's own show URL for an existing character" do
      allow(urls).to receive(:game_character_path).with(game, character).and_return("/games/1/characters/2")
      expect(presenter.cancel_href).to eq("/games/1/characters/2")
    end
  end

  describe "#name" do
    it "returns the character's name" do
      expect(presenter.name).to eq("Thornwall")
    end
  end

  describe "#content" do
    it "returns the character's sheet content" do
      expect(presenter.content).to eq("Sheet content")
    end
  end

  describe "#content?" do
    it "is true when content is present" do
      expect(presenter.content?).to be(true)
    end

    it "is false when content is blank" do
      blank_character = build_stubbed(:character, game: game, content: nil)
      presenter = described_class.new(blank_character, character_policy: character_policy, urls: urls)
      expect(presenter.content?).to be(false)
    end
  end

  describe "#archived?" do
    it "reflects the character's archived state" do
      expect(presenter.archived?).to be(false)

      archived = build_stubbed(:character, :archived, game: game)
      presenter = described_class.new(archived, character_policy: character_policy, urls: urls)
      expect(presenter.archived?).to be(true)
    end
  end

  describe "#hidden?" do
    it "reflects the character's hidden state" do
      expect(presenter.hidden?).to be(false)

      hidden = build_stubbed(:character, :hidden, game: game)
      presenter = described_class.new(hidden, character_policy: character_policy, urls: urls)
      expect(presenter.hidden?).to be(true)
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted character" do
      new_character = game.characters.new
      presenter = described_class.new(new_character, character_policy: character_policy, urls: urls)
      expect(presenter.new_record?).to be(true)
    end

    it "is false for a persisted character" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#id" do
    it "returns the character's id" do
      expect(presenter.id).to eq(character.id)
    end
  end

  describe "#errors?" do
    it "reports no errors on a clean character" do
      expect(presenter.errors?).to be(false)
    end

    it "reports errors when the character has validation errors" do
      character.errors.add(:name, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "surfaces full validation messages" do
      character.errors.add(:name, "can't be blank")
      expect(presenter.error_messages).to include("Name can't be blank")
    end
  end

  describe "#checkbox_value" do
    it "returns the character's id as a string" do
      expect(presenter.checkbox_value).to eq(character.id.to_s)
    end
  end
end
