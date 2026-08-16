require "rails_helper"

# Unit coverage of the module via a minimal host controller (the pattern used
# for TurnstileVerification). Exercises the slug lookup and the RequestMemo
# memoization directly so both are pinned without a full request.
RSpec.describe SceneScoped do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include SceneScoped
      attr_accessor :fake_params
      def params = fake_params
    end
  end

  let(:controller) { controller_class.new }
  let(:game) { create(:game) }

  describe "#game" do
    it "finds the game by the :game_id slug, not its numeric id" do
      controller.fake_params = { game_id: game.slug }
      expect(controller.send(:game)).to eq(game)
    end

    it "raises when no game has that slug" do
      controller.fake_params = { game_id: "no-such-slug" }
      expect { controller.send(:game) }.to raise_error(ActiveRecord::RecordNotFound)
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

  describe "#scene" do
    let(:scene) { create(:scene, game: game) }

    it "finds the scene by :id within the game's scenes" do
      controller.fake_params = { game_id: game.slug, id: scene.id.to_s }
      expect(controller.send(:scene)).to eq(scene)
    end

    it "memoizes: resolves once and returns the same instance thereafter" do
      controller.fake_params = { game_id: game.slug, id: scene.id.to_s }
      first = controller.send(:scene)
      expect(controller).not_to receive(:game)
      expect(controller.send(:scene)).to equal(first)
    end
  end
end
