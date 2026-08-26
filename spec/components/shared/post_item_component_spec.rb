require "rails_helper"

RSpec.describe Shared::PostItemComponent, type: :component do
  let(:user) { build_stubbed(:user, email: "author@example.com") }
  let(:raw_scene) { build_stubbed(:scene, resolved_at: nil) }
  let(:game) { build_stubbed(:game) }
  let(:urls) do
    double(
      mark_read_game_scene_post_path: "/games/1/scenes/2/posts/3/mark_read",
      edit_game_scene_post_path: "/games/1/scenes/2/posts/3/edit"
    )
  end
  let(:post_policy) { instance_double(PostPolicy, update?: false) }

  let(:post) do
    build_stubbed(:post,
      user: user,
      scene: raw_scene,
      content: "Hello **world**",
      is_ooc: false,
      last_edited_at: nil,
      created_at: Time.zone.parse("2024-06-15 14:30:00")).tap do |p|
      allow(p).to receive(:game).and_return(game)
    end
  end
  let(:presenter) { build_post_presenter(post) }

  subject(:component) { described_class.new(post: presenter) }

  before { allow(game).to receive(:game_master?).and_return(false) }

  def build_post_presenter(model, policy: post_policy)
    PostPresenter.new(model, game: game, urls: urls, policy: policy)
  end

  # Render once per example: ViewComponent 4.15 raises ReusedInstanceError if
  # the same instance is rendered twice (GHSA-8qw7-6phv-7q6p).
  def rendered_component
    @rendered_component ||= begin
      render_inline(component)
      page
    end
  end

  it "renders the post wrapper with the correct dom id" do
    expect(rendered_component).to have_css("##{ActionView::RecordIdentifier.dom_id(post)}")
  end

  describe "#ooc?" do
    it "is false for an in-character post" do
      expect(component.ooc?).to be false
    end
  end

  describe "#card_classes" do
    it "uses the white card tint for an in-character post" do
      expect(component.card_classes).to include("bg-card").and include("attn-item")
      expect(component.card_classes).not_to include("is-hot")
      expect(component.card_classes).not_to include("bg-tint-blue-bg")
    end

    it "adds is-hot when the post is unread" do
      recent = build_stubbed(:post, user: user, scene: raw_scene, content: "New", is_ooc: false,
        last_edited_at: nil, created_at: 1.hour.ago).tap { |p| allow(p).to receive(:game).and_return(game) }
      c = described_class.new(post: build_post_presenter(recent),
        scene: ScenePresenter.new(raw_scene), read_post_ids: Set.new)
      expect(c.card_classes).to include("is-hot")
    end
  end

  describe "#body_variant" do
    it "is :post_body for an in-character post" do
      expect(component.body_variant).to eq(:post_body)
    end

    it "is :post_body_ooc for an OOC post" do
      ooc_post = build_stubbed(:post, :ooc, user: user, scene: raw_scene, content: "OOC",
        created_at: Time.current).tap { |p| allow(p).to receive(:game).and_return(game) }
      expect(described_class.new(post: build_post_presenter(ooc_post)).body_variant).to eq(:post_body_ooc)
    end
  end

  describe "#byline_time" do
    it "wraps the formatted time in a <time> element carrying the iso8601 local-time data attr" do
      expect(component.byline_time).to eq(
        %(<time data-local-time="2024-06-15T14:30:00Z">Jun 15, 2024 2:30 PM</time>)
      )
    end
  end

  describe "#avatar_tone" do
    it "is gold when the author is not the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(component.avatar_tone).to eq(:gold)
    end

    it "is dark when the author is the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(component.avatar_tone).to eq(:dark)
    end
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
      build_stubbed(:post, :ooc, user: user, scene: raw_scene, content: "OOC note", created_at: Time.current).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:presenter) { build_post_presenter(post) }
    subject(:component) { described_class.new(post: presenter) }

    it "renders the OOC badge" do
      expect(rendered_component).to have_css("[data-testid='ooc-post']")
      expect(rendered_component).to have_text("OOC")
    end

    it "reports ooc? true" do
      expect(component.ooc?).to be true
    end

    it "uses the blue tint for the card" do
      expect(component.card_classes).to include("bg-tint-blue-bg")
      expect(component.card_classes).not_to include("bg-card")
    end
  end

  context "when edited" do
    let(:post) do
      build_stubbed(:post, :edited, user: user, scene: raw_scene, content: "Updated", created_at: Time.current).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:presenter) { build_post_presenter(post) }
    subject(:component) { described_class.new(post: presenter) }

    it "shows the edited indicator" do
      expect(rendered_component).to have_text("(edited)")
    end
  end

  context "when editable by the viewer" do
    let(:presenter) { build_post_presenter(post, policy: instance_double(PostPolicy, update?: true)) }

    it "renders an Edit link pointing at the presenter's edit URL" do
      render_inline(component)
      expect(page).to have_css("a[href='/games/1/scenes/2/posts/3/edit']", text: "Edit")
    end
  end

  context "unread aura" do
    let(:recent_post) do
      build_stubbed(:post, user: user, scene: raw_scene, content: "New post",
        is_ooc: false, last_edited_at: nil, created_at: 1.hour.ago).tap do |p|
        allow(p).to receive(:game).and_return(game)
      end
    end
    let(:recent_presenter) { build_post_presenter(recent_post) }
    let(:scene_presenter) { ScenePresenter.new(raw_scene) }

    context "when post is unread and recent" do
      subject(:component) do
        described_class.new(
          post: recent_presenter,
          scene: scene_presenter,
          read_post_ids: Set.new
        )
      end

      it "sets data-unread to true" do
        render_inline(component)
        expect(page).to have_css("[data-unread='true']")
      end

      it "includes the mark-read URL" do
        render_inline(component)
        expect(page).to have_css("[data-mark-read-url='/games/1/scenes/2/posts/3/mark_read']")
      end
    end

    context "when post is already read" do
      subject(:component) do
        described_class.new(
          post: recent_presenter,
          scene: scene_presenter,
          read_post_ids: Set.new([ recent_post.id ])
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
          post: build_post_presenter(post_in_resolved),
          scene: ScenePresenter.new(resolved_scene),
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
        described_class.new(post: recent_presenter)
      end

      it "sets data-unread to false" do
        render_inline(component)
        expect(page).to have_css("[data-unread='false']")
      end
    end
  end
end
