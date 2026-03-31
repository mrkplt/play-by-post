require "rails_helper"

RSpec.describe Shared::PostComposerComponent, type: :component do
  let(:game)  { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:post)  { build_stubbed(:post, scene: scene) }

  subject(:component) { described_class.new(post: post, game: game, scene: scene) }

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
    expect(rendered_component).to have_css("input[type='submit'][value='Post']")
  end

  it "renders the OOC checkbox" do
    expect(rendered_component).to have_css("input[type='checkbox'][name='post[is_ooc]']")
  end

  context "with validation errors" do
    before { post.errors.add(:content, "can't be blank") }

    it "renders the error" do
      expect(rendered_component).to have_text("Content can't be blank")
    end
  end

  context "when images are enabled" do
    before { allow(game).to receive(:images_disabled?).and_return(false) }

    it "renders the image file field" do
      expect(rendered_component).to have_css("input[type='file'][name='post[image]']")
    end
  end

  context "when images are disabled" do
    before { allow(game).to receive(:images_disabled?).and_return(true) }

    it "does not render the image file field" do
      expect(rendered_component).not_to have_css("input[type='file'][name='post[image]']")
    end
  end
end
