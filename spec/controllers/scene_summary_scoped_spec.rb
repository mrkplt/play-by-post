require "rails_helper"

# Unit coverage of the module via a minimal host controller (the pattern used
# for TurnstileVerification). Exercises the slug lookup, the RequestMemo
# memoization, and the summary chain directly so all are pinned without a full
# request.
RSpec.describe SceneSummaryScoped do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include SceneSummaryScoped
      attr_accessor :fake_params
      def params = fake_params
    end
  end

  let(:controller) { controller_class.new }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

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

  describe "#scene" do
    it "finds the scene by :scene_id within the game's scenes" do
      controller.fake_params = { game_id: game.slug, scene_id: scene.id.to_s }
      expect(controller.send(:scene)).to eq(scene)
    end

    it "memoizes: resolves once and returns the same instance thereafter" do
      controller.fake_params = { game_id: game.slug, scene_id: scene.id.to_s }
      first = controller.send(:scene)
      expect(controller).not_to receive(:game)
      expect(controller.send(:scene)).to equal(first)
    end
  end

  describe "#summary" do
    it "returns the scene's summary" do
      summary = create(:scene_summary, scene: scene)
      controller.fake_params = { game_id: game.slug, scene_id: scene.id.to_s }
      expect(controller.send(:summary)).to eq(summary)
    end

    it "is nil when the scene has no summary" do
      controller.fake_params = { game_id: game.slug, scene_id: scene.id.to_s }
      expect(controller.send(:summary)).to be_nil
    end
  end
end
