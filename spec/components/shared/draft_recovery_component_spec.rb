require "rails_helper"

RSpec.describe Shared::DraftRecoveryComponent, type: :component do
  let(:raw_game) { build_stubbed(:game) }
  let(:raw_scene) { build_stubbed(:scene, game: raw_game) }
  let(:urls) { double(discard_draft_game_scene_posts_path: "/games/1/scenes/2/posts/discard_draft") }

  let(:game_presenter) { GamePresenter.new(raw_game, policy: instance_double(GamePolicy, manage?: true)) }
  let(:scene_presenter) { ScenePresenter.new(raw_scene, game: raw_game, urls: urls) }

  def build_component(draft:)
    described_class.new(game: game_presenter, scene: scene_presenter, draft: draft)
  end

  it "renders nothing when there is no draft" do
    render_inline(build_component(draft: nil))
    expect(page).to have_no_text("unsaved draft")
  end

  it "reports draft? false when there is no draft" do
    expect(build_component(draft: nil).draft?).to be(false)
  end

  context "when a draft is present" do
    let(:draft_record) { build_stubbed(:post, :draft, scene: raw_scene, content: "Half-written reply") }
    let(:draft) { PostPresenter.new(draft_record) }

    it "reports draft? true" do
      expect(build_component(draft: draft).draft?).to be(true)
    end

    it "shows the unsaved draft notice" do
      render_inline(build_component(draft: draft))
      expect(page).to have_text("You have an unsaved draft from this scene.")
    end

    it "renders the draft content" do
      render_inline(build_component(draft: draft))
      expect(page).to have_text("Half-written reply")
    end

    it "renders a Discard Draft control pointing at the discard path" do
      render_inline(build_component(draft: draft))
      expect(page).to have_css(
        "a[href='/games/1/scenes/2/posts/discard_draft']",
        text: "Discard Draft"
      )
    end
  end
end
