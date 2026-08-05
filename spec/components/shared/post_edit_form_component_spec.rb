require "rails_helper"

RSpec.describe Shared::PostEditFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:post_record) { build_stubbed(:post, scene: scene, content: "Original body") }

  subject(:render_form) do
    render_inline(described_class.new(game: game, scene: scene, post: post_record))
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

  it "renders a live preview target and save/cancel controls" do
    render_form
    expect(page).to have_css("[data-markdown-preview-target='preview']")
    expect(page).to have_button("Save")
    expect(page).to have_link("Cancel", href: Rails.application.routes.url_helpers.game_scene_path(game, scene))
  end
end
