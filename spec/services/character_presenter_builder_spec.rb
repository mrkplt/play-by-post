require "rails_helper"

RSpec.describe CharacterPresenterBuilder do
  let(:current_user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }
  let(:game_policy) { GamePolicy.new(current_user, game) }
  let(:character) { build_stubbed(:character, game: game) }
  let(:character_policy) { CharacterPolicy.new(current_user, character) }
  let(:urls) { double("urls") }

  subject(:builder) { described_class.new(game, game_policy, urls: urls) }

  describe "#game_presenter" do
    it "wraps the game with the injected policy" do
      result = builder.game_presenter
      expect(result).to be_a(GamePresenter)
      expect(result.model).to eq(game)
    end

    it "constructs GamePresenter with exactly the game and the injected policy" do
      allow(GamePresenter).to receive(:new).and_call_original
      builder.game_presenter
      expect(GamePresenter).to have_received(:new).with(game, policy: game_policy)
    end
  end

  describe "#character_presenter" do
    it "wraps the character with the injected policy and urls" do
      result = builder.character_presenter(character, character_policy)
      expect(result).to be_a(CharacterPresenter)
      expect(result.__getobj__).to eq(character)
    end

    it "constructs CharacterPresenter with exactly the character, character_policy, and urls" do
      allow(CharacterPresenter).to receive(:new).and_call_original
      builder.character_presenter(character, character_policy)
      expect(CharacterPresenter).to have_received(:new)
        .with(character, character_policy: character_policy, urls: urls)
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

      result = builder.versions(character)
      expect(result).to all(be_a(CharacterVersionPresenter))
      expect(result.map(&:__getobj__)).to eq([ version ])
    end
  end
end
