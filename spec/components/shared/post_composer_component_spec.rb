require "rails_helper"

RSpec.describe Shared::PostComposerComponent, type: :component do
  let(:raw_game)  { build_stubbed(:game) }
  let(:raw_scene) { build_stubbed(:scene, game: raw_game) }
  let(:raw_post)  { build_stubbed(:post, scene: raw_scene) }

  let(:urls) { double(save_draft_game_scene_posts_path: "/games/1/scenes/2/posts/save_draft") }
  let(:game_presenter) { GamePresenter.new(raw_game, policy: instance_double(GamePolicy, manage?: true)) }
  let(:scene_presenter) { ScenePresenter.new(raw_scene, game: raw_game, urls: urls) }
  let(:post_presenter) { PostPresenter.new(raw_post) }

  subject(:component) { described_class.new(post: post_presenter, game: game_presenter, scene: scene_presenter) }

  def rendered_component
    render_inline(component)
    page
  end

  it "renders a form" do
    expect(rendered_component).to have_css("form")
  end

  it "renders the content textarea" do
    expect(rendered_component).to have_css("textarea[name='post[content]']")
  end

  it "renders the markdown preview target" do
    expect(rendered_component).to have_css("[data-markdown-preview-target='preview']")
  end

  it "renders the submit button" do
    expect(rendered_component).to have_css("[data-testid='composer-actions']")
    expect(rendered_component).to have_css("input[type='submit'][value='POST']")
  end

  it "renders the OOC checkbox" do
    expect(rendered_component).to have_css("input[type='checkbox'][name='post[is_ooc]']")
  end

  context "with validation errors" do
    before { raw_post.errors.add(:content, "can't be blank") }

    it "renders the error" do
      expect(rendered_component).to have_text("Content can't be blank")
    end
  end

  context "when images are enabled" do
    before { allow(raw_game).to receive(:images_disabled?).and_return(false) }

    it "renders the image file field" do
      expect(rendered_component).to have_css("input[type='file'][name='post[image]']")
    end
  end

  context "when images are disabled" do
    before { allow(raw_game).to receive(:images_disabled?).and_return(true) }

    it "does not render the image file field" do
      expect(rendered_component).not_to have_css("input[type='file'][name='post[image]']")
    end
  end

  context "with a draft" do
    let(:draft_record) { build_stubbed(:post, :draft, scene: raw_scene, content: "Half-written") }
    let(:draft_presenter) { PostPresenter.new(draft_record) }

    subject(:component) do
      described_class.new(post: post_presenter, game: game_presenter, scene: scene_presenter, draft: draft_presenter)
    end

    it "pre-fills the editor with the draft content" do
      expect(rendered_component).to have_css("textarea", text: "Half-written")
    end
  end
end
