require "rails_helper"

RSpec.describe Shared::PostItemComponent, type: :component do
  let(:user) { build_stubbed(:user, email: "author@example.com") }
  let(:scene) { build_stubbed(:scene, resolved_at: nil) }
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

  context "unread aura" do
    let(:recent_post) do
      build_stubbed(:post, user: user, scene: scene, content: "New post",
        is_ooc: false, last_edited_at: nil, created_at: 1.hour.ago).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:recent_presenter) { PostPresenter.new(recent_post) }

    context "when post is unread and recent" do
      subject(:component) do
        described_class.new(
          post: recent_presenter,
          game: game,
          current_user: user,
          scene: scene,
          read_post_ids: Set.new
        )
      end

      it "sets data-unread to true" do
        render_inline(component)
        expect(page).to have_css("[data-unread='true']")
      end

      it "includes the mark-read URL" do
        render_inline(component)
        expect(page).to have_css("[data-mark-read-url]")
      end
    end

    context "when post is already read" do
      subject(:component) do
        described_class.new(
          post: recent_presenter,
          game: game,
          current_user: user,
          scene: scene,
          read_post_ids: Set.new([recent_post.id])
        )
      end

      it "sets data-unread to false" do
        render_inline(component)
        expect(page).to have_css("[data-unread='false']")
      end
    end

    context "when scene is resolved" do
      let(:resolved_scene) { build_stubbed(:scene, resolved_at: 1.hour.ago) }
      let(:post_in_resolved) do
        build_stubbed(:post, user: user, scene: resolved_scene, content: "Old",
          is_ooc: false, last_edited_at: nil, created_at: 1.hour.ago).tap do |p|
          allow(p).to receive(:game).and_return(game)
        end
      end

      subject(:component) do
        described_class.new(
          post: PostPresenter.new(post_in_resolved),
          game: game,
          current_user: user,
          scene: resolved_scene,
          read_post_ids: Set.new
        )
      end

      it "sets data-unread to false" do
        render_inline(component)
        expect(page).to have_css("[data-unread='false']")
      end
    end

    context "when no read_post_ids provided" do
      subject(:component) do
        described_class.new(post: recent_presenter, game: game, current_user: user)
      end

      it "sets data-unread to false" do
        render_inline(component)
        expect(page).to have_css("[data-unread='false']")
      end
    end
  end
end
