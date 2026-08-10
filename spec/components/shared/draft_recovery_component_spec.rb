require "rails_helper"

RSpec.describe Shared::DraftRecoveryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }

  def build_component(draft:)
    described_class.new(game: game, scene: scene, draft: draft)
  end

  it "renders nothing when there is no draft" do
    render_inline(build_component(draft: nil))
    expect(page).to have_no_text("unsaved draft")
  end

  it "reports draft? false when there is no draft" do
    expect(build_component(draft: nil).draft?).to be(false)
  end

  context "when a draft is present" do
    let(:draft) { build_stubbed(:post, :draft, scene: scene, content: "Half-written reply") }

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
        "a[href='#{Rails.application.routes.url_helpers.discard_draft_game_scene_posts_path(game, scene)}']",
        text: "Discard Draft"
      )
    end
  end
end
