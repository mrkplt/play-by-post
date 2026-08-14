require "rails_helper"

RSpec.describe CharacterPresenterBuilder do
  let(:current_user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }
  let(:game_policy) { GamePolicy.new(current_user, game) }
  let(:character) { build_stubbed(:character, game: game) }
  let(:character_policy) { CharacterPolicy.new(current_user, character) }

  subject(:builder) { described_class.new(game, game_policy) }

  describe "#game_presenter" do
    it "wraps the game with the injected policy" do
      result = builder.game_presenter
      expect(result).to be_a(GamePresenter)
      expect(result.model).to eq(game)
    end
  end

  describe "#character_presenter" do
    it "wraps the character with both policies and the active players" do
      where_rel = double("where rel")
      includes_rel = double("includes rel")
      allow(game).to receive(:active_members).and_return(double(where: where_rel))
      allow(where_rel).to receive(:includes).with(:user).and_return(includes_rel)
      allow(includes_rel).to receive(:map).and_return([])

      result = builder.character_presenter(character, character_policy)
      expect(result).to be_a(CharacterPresenter)
    end
  end

  describe "#versions" do
    it "returns each character version, newest first, wrapped as presenters" do
      version = build_stubbed(:character_version)
      ordered_rel = double("ordered rel")
      allow(character).to receive(:character_versions).and_return(double(order: ordered_rel))
      allow(ordered_rel).to receive(:includes).with(:edited_by).and_return([ version ])

      result = builder.versions(character)
      expect(result).to all(be_a(CharacterVersionPresenter))
      expect(result.map(&:__getobj__)).to eq([ version ])
    end
  end
end
