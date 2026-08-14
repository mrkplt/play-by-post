require "rails_helper"

RSpec.describe PostPresenterBuilder do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene) }
  let(:urls) { double("urls") }
  let(:post) { build_stubbed(:post) }
  let(:current_user) { build_stubbed(:user) }
  let(:policy) { PostPolicy.new(current_user, post) }

  subject(:builder) { described_class.new(game, scene, urls) }

  describe "#post_presenter" do
    it "wraps the post with the injected game, scene, urls and policy" do
      result = builder.post_presenter(post, policy)
      expect(result).to be_a(PostPresenter)
      expect(result.__getobj__).to eq(post)
    end

    it "carries scene_participants through when supplied" do
      participant = instance_double(SceneParticipant, user_id: post.user_id, display_name: "Lady Ashford")
      result = builder.post_presenter(post, policy, scene_participants: [ participant ])

      expect(result.author_display_name).to eq("Lady Ashford")
    end
  end

  describe "#composer_component" do
    it "builds a composer component wrapping the post presenter" do
      game_presenter = GamePresenter.new(game, policy: GamePolicy.new(current_user, game))
      scene_presenter = ScenePresenter.new(scene)

      result = builder.composer_component(post, policy, game_presenter, scene_presenter)
      expect(result).to be_a(Shared::PostComposerComponent)
    end
  end
end
