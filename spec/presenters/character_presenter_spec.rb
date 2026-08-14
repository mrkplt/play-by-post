require "rails_helper"

RSpec.describe CharacterPresenter do
  let(:game) { build_stubbed(:game) }
  let(:character) { build_stubbed(:character, game: game, name: "Thornwall", content: "Sheet content") }
  let(:game_policy) { instance_double(GamePolicy, manage?: true) }
  let(:character_policy) { instance_double(CharacterPolicy, update?: true, assign_owner?: true) }

  subject(:presenter) do
    described_class.new(character, game_policy: game_policy, character_policy: character_policy)
  end

  describe "#can_manage_game?" do
    it "is true when the injected game policy allows management" do
      allow(game_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage_game?).to be(true)
    end

    it "is false when the injected game policy disallows management" do
      allow(game_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage_game?).to be(false)
    end
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
      presenter = described_class.new(blank_character, game_policy: game_policy, character_policy: character_policy)
      expect(presenter.content?).to be(false)
    end
  end

  describe "#archived?" do
    it "reflects the character's archived state" do
      expect(presenter.archived?).to be(false)

      archived = build_stubbed(:character, :archived, game: game)
      presenter = described_class.new(archived, game_policy: game_policy, character_policy: character_policy)
      expect(presenter.archived?).to be(true)
    end
  end

  describe "#hidden?" do
    it "reflects the character's hidden state" do
      expect(presenter.hidden?).to be(false)

      hidden = build_stubbed(:character, :hidden, game: game)
      presenter = described_class.new(hidden, game_policy: game_policy, character_policy: character_policy)
      expect(presenter.hidden?).to be(true)
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted character" do
      new_character = game.characters.new
      presenter = described_class.new(new_character, game_policy: game_policy, character_policy: character_policy)
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

  describe "#owner_options" do
    it "is empty when no players are injected" do
      expect(presenter.owner_options).to eq([])
    end

    it "uses display name when present and falls back to email otherwise" do
      named = build_stubbed(:user, email: "elf@example.com")
      allow(named).to receive(:display_name).and_return("Elrond")
      nameless = build_stubbed(:user, email: "orc@example.com")
      allow(nameless).to receive(:display_name).and_return(nil)

      presenter = described_class.new(
        character, game_policy: game_policy, character_policy: character_policy,
        players: [ named, nameless ]
      )

      expect(presenter.owner_options).to eq([ [ "Elrond", named.id ], [ "orc@example.com", nameless.id ] ])
    end
  end

  describe "#checkbox_value" do
    it "returns the character's id as a string" do
      expect(presenter.checkbox_value).to eq(character.id.to_s)
    end
  end
end
