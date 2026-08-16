require "rails_helper"

# Unit coverage of the module via a minimal host controller (the pattern used
# for TurnstileVerification). Exercises the slug lookup and the RequestMemo
# memoization directly so both are pinned without a full request.
RSpec.describe CharacterScoped do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include CharacterScoped
      attr_accessor :fake_params
      def params = fake_params
    end
  end

  let(:controller) { controller_class.new }
  let(:game) { create(:game) }
  let(:player) { create(:user) }

  describe "#game" do
    it "finds the game by the :game_id slug, not its numeric id" do
      controller.fake_params = { game_id: game.slug }
      expect(controller.send(:game)).to eq(game)
    end

    it "does not accept the numeric id as a slug" do
      controller.fake_params = { game_id: game.id.to_s }
      expect { controller.send(:game) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "memoizes: resolves once and returns the same instance thereafter" do
      controller.fake_params = { game_id: game.slug }
      expect(Game).to receive(:find_by!).once.and_call_original
      first = controller.send(:game)
      expect(controller.send(:game)).to equal(first)
    end
  end

  describe "#character" do
    let(:character) { create(:character, game: game, user: player) }

    it "finds the character by :id within the game's characters" do
      controller.fake_params = { game_id: game.slug, id: character.id.to_s }
      expect(controller.send(:character)).to eq(character)
    end

    it "memoizes: resolves once and returns the same instance thereafter" do
      controller.fake_params = { game_id: game.slug, id: character.id.to_s }
      first = controller.send(:character)
      expect(controller).not_to receive(:game)
      expect(controller.send(:character)).to equal(first)
    end
  end
end
