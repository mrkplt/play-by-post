require "rails_helper"

RSpec.describe Shared::UnreadAuraComponent, type: :component do
  let(:raw_scene) { build_stubbed(:scene, resolved_at: nil) }
  let(:scene) { ScenePresenter.new(raw_scene) }

  def render_with(post_presenters)
    render_inline(described_class.new(
      post_presenters: post_presenters, scene: scene, read_post_ids: Set.new
    ))
    page
  end

  describe "the posts container" do
    it "mounts the unread-aura and stream-dedupe controllers on the #posts container" do
      expect(render_with([])).to have_css("div#posts[data-controller='unread-aura stream-dedupe']")
    end

    it "keeps the #posts id so the Turbo Stream append target survives" do
      expect(render_with([])).to have_css("div#posts")
    end
  end

  describe "with no posts" do
    it "renders the empty-state message" do
      expect(render_with([])).to have_css("#no_posts_message", text: "No posts yet. Be the first!")
    end

    it "reports posts_empty? true" do
      expect(described_class.new(post_presenters: [], scene: scene, read_post_ids: Set.new).posts_empty?)
        .to be(true)
    end
  end

  describe "with posts" do
    let(:user) { build_stubbed(:user, email: "author@example.com") }
    let(:game) { build_stubbed(:game) }
    let(:urls) do
      double(
        mark_read_game_scene_post_path: "/mark_read",
        edit_game_scene_post_path: "/edit"
      )
    end
    let(:post) do
      build_stubbed(:post, user: user, scene: raw_scene, content: "Hello",
        is_ooc: false, last_edited_at: nil,
        created_at: Time.zone.parse("2024-06-15 14:30:00")).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:presenter) do
      PostPresenter.new(post, game: game, urls: urls, policy: instance_double(PostPolicy, update?: false))
    end

    before { allow(game).to receive(:game_master?).and_return(false) }

    it "renders a post item per presenter" do
      page = render_with([ presenter ])
      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(post)}")
      expect(page).to have_no_css("#no_posts_message")
    end

    it "reports posts_empty? false" do
      expect(described_class.new(post_presenters: [ presenter ], scene: scene, read_post_ids: Set.new).posts_empty?)
        .to be(false)
    end
  end
end
