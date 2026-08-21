require "rails_helper"

RSpec.describe SceneShowBuilder, :db do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:viewer) { create(:user, :with_profile) }
  let(:urls) { double("urls") }

  let(:context) do
    described_class::Context.new(
      current_user: viewer, urls: urls, policies: ->(record) { PostPolicy.new(viewer, record) }
    )
  end

  def builder = described_class.new(scene, game: game, context: context)

  before { create(:game_member, game: game, user: viewer) }

  describe "#scene_presenter" do
    it "wraps the scene" do
      expect(builder.scene_presenter).to be_a(ScenePresenter)
    end

    it "memoizes, so every panel shares one instance" do
      built = builder

      expect(built.scene_presenter).to be(built.scene_presenter)
    end
  end

  describe "#navigation_presenter" do
    it "builds navigation over the scene presenter" do
      expect(builder.navigation_presenter).to be_a(SceneNavigationPresenter)
    end
  end

  describe "#show_presenter" do
    it "builds the viewer-scoped show state" do
      expect(builder.show_presenter).to be_a(SceneShowPresenter)
    end
  end

  describe "#posts_presenter" do
    it "builds the post list" do
      expect(builder.posts_presenter).to be_a(ScenePostsPresenter)
    end

    it "wraps each published post" do
      create(:scene_participant, scene: scene, user: viewer)
      create(:post, scene: scene, user: viewer, draft: false)

      expect(builder.posts_presenter.post_presenters.map(&:class)).to eq([ PostPresenter ])
    end

    it "leaves drafts out of the thread" do
      create(:scene_participant, scene: scene, user: viewer)
      create(:post, scene: scene, user: viewer, draft: true)

      expect(builder.posts_presenter.post_presenters).to be_empty
    end

    it "resolves each post's policy through the injected callable" do
      create(:scene_participant, scene: scene, user: viewer)
      create(:post, scene: scene, user: viewer, draft: false)
      resolved = []
      context = described_class::Context.new(
        current_user: viewer, urls: urls,
        policies: ->(record) { resolved << record; PostPolicy.new(viewer, record) }
      )

      described_class.new(scene, game: game, context: context).posts_presenter.post_presenters

      expect(resolved).to all(be_a(Post))
    end
  end

  describe "#summary_presenter" do
    it "is nil while the scene has no summary" do
      expect(builder.summary_presenter).to be_nil
    end

    it "wraps the summary once there is one" do
      create(:scene_summary, scene: scene)

      expect(builder.summary_presenter).to be_a(SceneSummaryPresenter)
    end

    it "hides a draft summary from a non-GM viewer" do
      create(:scene_summary, scene: scene, draft: true)

      expect(builder.summary_presenter).to be_nil
    end

    it "shows a draft summary to the GM who authored it" do
      gm = create(:user, :with_profile)
      create(:game_member, :game_master, game: game, user: gm)
      create(:scene_summary, scene: scene, draft: true)
      gm_context = described_class::Context.new(
        current_user: gm, urls: urls, policies: ->(record) { PostPolicy.new(gm, record) }
      )
      gm_builder = described_class.new(scene, game: game, context: gm_context)

      expect(gm_builder.summary_presenter).to be_a(SceneSummaryPresenter)
    end

    it "hides an AI-generated summary from a viewer whose AI display preference is hidden" do
      create(:scene_summary, :ai_generated, scene: scene)
      viewer.user_profile.update!(ai_display_preference: :hidden)

      expect(builder.summary_presenter).to be_nil
    end

    it "shows an AI-generated summary to a viewer whose AI display preference is tagged" do
      create(:scene_summary, :ai_generated, scene: scene)
      viewer.user_profile.update!(ai_display_preference: :tagged)

      expect(builder.summary_presenter).to be_a(SceneSummaryPresenter)
    end

    it "shows a hand-written summary even to a viewer whose AI display preference is hidden" do
      create(:scene_summary, scene: scene)
      viewer.user_profile.update!(ai_display_preference: :hidden)

      expect(builder.summary_presenter).to be_a(SceneSummaryPresenter)
    end

    it "threads the viewer through to the summary presenter's AI badge preference" do
      create(:scene_summary, :ai_generated, scene: scene)
      viewer.user_profile.update!(ai_display_preference: :shown)

      expect(builder.summary_presenter.show_ai_badge?).to be(false)
    end

    it "shows an AI-generated summary to a viewer who has no profile yet" do
      profileless_viewer = create(:user)
      create(:game_member, game: game, user: profileless_viewer)
      create(:scene_summary, :ai_generated, scene: scene)
      profileless_context = described_class::Context.new(
        current_user: profileless_viewer, urls: urls, policies: ->(record) { PostPolicy.new(profileless_viewer, record) }
      )
      profileless_builder = described_class.new(scene, game: game, context: profileless_context)

      expect(profileless_builder.summary_presenter).to be_a(SceneSummaryPresenter)
    end
  end

  describe "#screen" do
    let(:game_presenter) { GamePresenter.new(game, policy: GamePolicy.new(viewer, game)) }

    it "bundles the parts into one screen presenter" do
      expect(builder.screen(game_presenter)).to be_a(SceneScreenPresenter)
    end

    it "carries the game presenter it was handed" do
      expect(builder.screen(game_presenter).game).to be(game_presenter)
    end

    it "carries the same scene presenter the builder memoized" do
      built = builder

      expect(built.screen(game_presenter).scene).to be(built.scene_presenter)
    end

    it "carries the summary when the scene has one" do
      create(:scene_summary, scene: scene)

      expect(builder.screen(game_presenter).summary).to be_a(SceneSummaryPresenter)
    end
  end
end
