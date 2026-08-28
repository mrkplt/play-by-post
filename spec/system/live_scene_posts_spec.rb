require "rails_helper"

# Live scene chat (Fizzy #123): a viewer on a scene page receives posts other
# people create or edit without reloading. The page subscribes every viewer to
# [scene, :posts] (PostsChannel authorizes); PostBroadcast pushes new/edited
# posts to it. Stands in for another participant posting from their own session
# by creating the post server-side and broadcasting it — the same path the
# controller drives.
RSpec.describe "Live scene posts", type: :feature do
  let(:game) { create(:game, name: "The Long Road") }
  let(:viewer) { create(:user, :with_profile) }
  let(:other) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game, private: false, title: "The Crossing") }

  before do
    create(:game_member, :game_master, game: game, user: viewer)
    create(:game_member, game: game, user: other)
    create(:scene_participant, scene: scene, user: viewer)
    create(:scene_participant, scene: scene, user: other)
  end

  def broadcast_new_post(content:, is_ooc: false)
    post = create(:post, scene: scene, user: other, content: content, is_ooc: is_ooc)
    PostBroadcast.new(post).created
    post
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "appends another participant's new post live, without a reload" do
        sign_in_as(viewer)
        visit game_scene_path(game, scene)
        connect_turbo_cable_stream_sources

        broadcast_new_post(content: "A rider approaches from the east.")

        expect(page).to have_text("A rider approaches from the east.", wait: 8)
        # Viewer-neutral render: no Edit link on someone else's streamed post.
        within("##{ActionView::RecordIdentifier.dom_id(scene.posts.published.last)}") do
          expect(page).to have_no_link("Edit")
        end
      end

      it "reflects a live edit of an existing post in place" do
        existing = create(:post, scene: scene, user: other, content: "Original line.")
        sign_in_as(viewer)
        visit game_scene_path(game, scene)
        connect_turbo_cable_stream_sources

        existing.update!(content: "Corrected line.", last_edited_at: Time.current)
        PostBroadcast.new(existing).updated

        expect(page).to have_text("Corrected line.", wait: 8)
        expect(page).to have_no_text("Original line.")
      end
    end
  end

  it "hides a live-streamed OOC post for a viewer who has OOC hidden" do
    viewer.user_profile.update!(hide_ooc: true)
    sign_in_as(viewer)
    visit game_scene_path(game, scene)
    connect_turbo_cable_stream_sources

    broadcast_new_post(content: "brb, coffee", is_ooc: true)

    # The node arrives (it is in the DOM) but the ooc-filter controller hides it.
    ooc_post = scene.posts.published.last
    expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(ooc_post)}", visible: :hidden, wait: 8)
    expect(page).to have_no_text("brb, coffee")
  end
end
