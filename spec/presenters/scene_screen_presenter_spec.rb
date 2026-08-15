require "rails_helper"

# The parts are real presenters rather than doubles: the constructor is sig'd
# with concrete types, which sorbet-runtime enforces at runtime.
RSpec.describe SceneScreenPresenter, :db do
  let(:game_record) { create(:game) }
  let(:scene_record) { create(:scene, game: game_record) }
  let(:viewer) { create(:user, :with_profile) }

  let(:game) { GamePresenter.new(game_record, policy: GamePolicy.new(viewer, game_record)) }
  let(:scene) { ScenePresenter.new(scene_record, game: game_record) }
  let(:navigation) { SceneNavigationPresenter.new(scene, game: game_record) }
  let(:show) { SceneShowPresenter.new(scene, game: game_record, current_user: viewer) }
  let(:posts) do
    ScenePostsPresenter.new(
      scene, game: game_record, current_user: viewer,
      post_policy: PostPolicy.new(viewer, scene_record.posts.new), post_presenters: []
    )
  end
  let(:summary) do
    SceneSummaryPresenter.new(
      create(:scene_summary, scene: scene_record),
      game: game_record, policy: SceneSummaryPolicy.new(viewer, create(:scene_summary))
    )
  end

  def screen(summary_presenter: nil)
    described_class.new(
      scene,
      game_presenter: game, navigation: navigation,
      show: show, posts: posts, summary: summary_presenter
    )
  end

  it "exposes each part it was built with" do
    presenter = screen(summary_presenter: summary)

    expect(presenter.game).to be(game)
    expect(presenter.scene).to be(scene)
    expect(presenter.navigation).to be(navigation)
    expect(presenter.show).to be(show)
    expect(presenter.posts).to be(posts)
    expect(presenter.summary).to be(summary)
  end

  it "carries no summary when none was supplied" do
    expect(screen.summary).to be_nil
  end

  describe "#summary?" do
    it "is true for a resolved scene with a summary" do
      scene_record.update!(resolved_at: Time.current)

      expect(screen(summary_presenter: summary).summary?).to be(true)
    end

    it "is false for a resolved scene with no summary yet" do
      scene_record.update!(resolved_at: Time.current)

      expect(screen.summary?).to be(false)
    end

    it "is false for an unresolved scene that somehow has one" do
      expect(screen(summary_presenter: summary).summary?).to be(false)
    end
  end

  describe "#gm_actions?" do
    it "is true when a manager views an open scene" do
      create(:game_member, :game_master, game: game_record, user: viewer)

      expect(screen.gm_actions?).to be(true)
    end

    it "is false once the scene is resolved" do
      create(:game_member, :game_master, game: game_record, user: viewer)
      scene_record.update!(resolved_at: Time.current)

      expect(screen.gm_actions?).to be(false)
    end

    it "is false for a viewer who cannot manage the game" do
      create(:game_member, game: game_record, user: viewer)

      expect(screen.gm_actions?).to be(false)
    end
  end
end
