require "rails_helper"

RSpec.describe Shared::PostEditFormComponent, type: :component do
  let(:raw_game) { build_stubbed(:game) }
  let(:raw_scene) { build_stubbed(:scene, game: raw_game) }
  let(:post_record) { build_stubbed(:post, scene: raw_scene, content: "Original body") }

  let(:game_presenter) { GamePresenter.new(raw_game, policy: instance_double(GamePolicy, manage?: true)) }
  let(:scene_presenter) { ScenePresenter.new(raw_scene) }
  let(:post_presenter) { PostPresenter.new(post_record) }

  subject(:render_form) do
    render_inline(described_class.new(game: game_presenter, scene: scene_presenter, post: post_presenter))
  end

  it "renders the markdown toolbar over the post body editor" do
    render_form
    expect(page).to have_css("div[role='toolbar'][aria-label='Markdown formatting']")
    expect(page).to have_css("textarea.markdown-editor[data-markdown-toolbar-target='input'][data-markdown-preview-target='input']")
  end

  it "pre-fills the editor with the existing post content" do
    render_form
    expect(page).to have_css("textarea", text: "Original body")
  end

  it "renders a live preview target" do
    render_form
    expect(page).to have_css("[data-markdown-preview-target='preview']")
  end

  it "gives the form a stable id for the external submit button" do
    render_form
    expect(page).to have_css("form#edit_post_#{post_record.id}_form")
  end
end
