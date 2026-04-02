require "rails_helper"

RSpec.describe Shared::PostItemComponent, type: :component do
  let(:user) { build_stubbed(:user, email: "author@example.com") }
  let(:scene) { build_stubbed(:scene) }
  let(:game) { build_stubbed(:game) }
  let(:post) do
    build_stubbed(:post,
      user: user,
      scene: scene,
      content: "Hello **world**",
      is_ooc: false,
      last_edited_at: nil,
      created_at: Time.zone.parse("2024-06-15 14:30:00")).tap do |p|
      allow(p).to receive(:game).and_return(game)
    end
  end
  let(:presenter) { PostPresenter.new(post) }

  subject(:component) { described_class.new(post: presenter, game: game, current_user: user) }

  def rendered_component
    render_inline(component)
    page
  end

  it "renders the post wrapper with the correct dom id" do
    expect(rendered_component).to have_css("##{ActionView::RecordIdentifier.dom_id(post)}")
  end

  it "renders the author display name" do
    allow(user).to receive(:display_name).and_return("Jane Doe")
    expect(rendered_component).to have_text("Jane Doe")
  end

  it "renders the formatted timestamp" do
    expect(rendered_component).to have_css("time")
  end

  it "renders the markdown content as HTML" do
    expect(rendered_component).to have_css("[data-testid='post-content']")
    expect(rendered_component).to have_css("strong", text: "world")
  end

  context "when OOC" do
    let(:post) do
      build_stubbed(:post, :ooc, user: user, scene: scene, content: "OOC note", created_at: Time.current).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:presenter) { PostPresenter.new(post) }
    subject(:component) { described_class.new(post: presenter, game: game, current_user: user) }

    it "renders the OOC badge" do
      expect(rendered_component).to have_css("[data-testid='ooc-post']")
      expect(rendered_component).to have_text("OOC")
    end
  end

  context "when edited" do
    let(:post) do
      build_stubbed(:post, :edited, user: user, scene: scene, content: "Updated", created_at: Time.current).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:presenter) { PostPresenter.new(post) }
    subject(:component) { described_class.new(post: presenter, game: game, current_user: user) }

    it "shows the edited indicator" do
      expect(rendered_component).to have_text("(edited)")
    end
  end
end
