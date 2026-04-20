# typed: false

require "rails_helper"

RSpec.describe PostsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  describe "POST /games/:game_id/scenes/:scene_id/posts (create)" do
    context "when participant has no existing draft" do
      it "creates a published post and redirects" do
        sign_in(player)
        post game_scene_posts_path(game, scene), params: { post: { content: "Hello world", is_ooc: false } }
        expect(response).to redirect_to(game_scene_path(game, scene))
        expect(scene.posts.published.count).to eq(1)
      end

      it "renders turbo_stream on success" do
        sign_in(player)
        post game_scene_posts_path(game, scene),
          params: { post: { content: "Hello world", is_ooc: false } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
      end

      it "includes post content in turbo_stream response" do
        sign_in(player)
        post game_scene_posts_path(game, scene),
          params: { post: { content: "Unique turbo post text", is_ooc: false } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Unique turbo post text")
      end

      it "redirects with alert on failure" do
        sign_in(player)
        post game_scene_posts_path(game, scene), params: { post: { content: "", is_ooc: false } }
        expect(response).to redirect_to(game_scene_path(game, scene))
      end

      it "renders turbo_stream on failure with turbo request" do
        sign_in(player)
        post game_scene_posts_path(game, scene),
          params: { post: { content: "", is_ooc: false } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when participant has an existing draft" do
      it "publishes the draft" do
        draft = create(:post, :draft, scene: scene, user: player)
        sign_in(player)
        post game_scene_posts_path(game, scene), params: { post: { content: "Published from draft", is_ooc: false } }
        expect(response).to redirect_to(game_scene_path(game, scene))
        expect(draft.reload.draft).to eq(false)
        expect(draft.reload.content).to eq("Published from draft")
      end

      it "creates a new post without modifying an existing published post when no draft exists" do
        existing = create(:post, scene: scene, user: player, content: "Existing published post")
        sign_in(player)
        post game_scene_posts_path(game, scene), params: { post: { content: "Brand new post", is_ooc: false } }
        expect(existing.reload.content).to eq("Existing published post")
        expect(scene.posts.published.count).to eq(2)
      end
    end

    it "blocks unauthenticated requests" do
      post game_scene_posts_path(game, scene), params: { post: { content: "Hi" } }
      expect(response).to have_http_status(:redirect)
    end

    it "blocks non-participants" do
      outsider = create(:user)
      create(:game_member, game: game, user: outsider)
      sign_in(outsider)
      post game_scene_posts_path(game, scene), params: { post: { content: "Hi" } }
      expect(response).to redirect_to(game_scene_path(game, scene))
    end

    it "blocks a removed member from creating a post" do
      removed = create(:user, :with_profile)
      create(:game_member, :removed, game: game, user: removed)
      create(:scene_participant, scene: scene, user: removed)
      sign_in(removed)
      post game_scene_posts_path(game, scene), params: { post: { content: "Hi", is_ooc: false } }
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/write access/i)
    end
  end

  describe "GET /games/:game_id/scenes/:scene_id/posts/:id/edit" do
    it "renders edit form for post within edit window" do
      post = create(:post, scene: scene, user: player)
      sign_in(player)
      get edit_game_scene_post_path(game, scene, post)
      expect(response).to have_http_status(:ok)
    end

    it "redirects when post is outside edit window" do
      game.update!(post_edit_window_minutes: 10)
      post = create(:post, scene: scene, user: player, created_at: 11.minutes.ago)
      sign_in(player)
      get edit_game_scene_post_path(game, scene, post)
      expect(response).to redirect_to(game_scene_path(game, scene))
    end
  end

  describe "PATCH /games/:game_id/scenes/:scene_id/posts/:id (update)" do
    it "updates post content and redirects" do
      post_record = create(:post, scene: scene, user: player)
      sign_in(player)
      patch game_scene_post_path(game, scene, post_record), params: { post: { content: "Updated content" } }
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(post_record.reload.content).to eq("Updated content")
    end

    it "renders turbo_stream on update" do
      post_record = create(:post, scene: scene, user: player)
      sign_in(player)
      patch game_scene_post_path(game, scene, post_record),
        params: { post: { content: "Updated" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end

    it "includes updated content in turbo_stream response" do
      post_record = create(:post, scene: scene, user: player)
      sign_in(player)
      patch game_scene_post_path(game, scene, post_record),
        params: { post: { content: "Turbo updated content here" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Turbo updated content here")
    end

    it "redirects with alert when outside edit window" do
      game.update!(post_edit_window_minutes: 10)
      post_record = create(:post, scene: scene, user: player, created_at: 11.minutes.ago)
      sign_in(player)
      patch game_scene_post_path(game, scene, post_record), params: { post: { content: "Too late" } }
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(post_record.reload.content).not_to eq("Too late")
    end

    it "sets last_edited_at on successful update" do
      post_record = create(:post, scene: scene, user: player, last_edited_at: nil)
      sign_in(player)
      patch game_scene_post_path(game, scene, post_record), params: { post: { content: "Edited content" } }
      expect(post_record.reload.last_edited_at).to be_within(5.seconds).of(Time.current)
    end
  end

  describe "POST /games/:game_id/scenes/:scene_id/posts/:id/mark_read" do
    it "marks a post as read and returns no_content" do
      post_record = create(:post, scene: scene, user: gm)
      sign_in(player)
      post mark_read_game_scene_post_path(game, scene, post_record)
      expect(response).to have_http_status(:no_content)
      expect(PostRead.where(post: post_record, user: player).count).to eq(1)
    end
  end

  describe "PATCH /games/:game_id/scenes/:scene_id/posts/save_draft" do
    it "creates a new draft" do
      sign_in(player)
      patch save_draft_game_scene_posts_path(game, scene),
        params: { post: { content: "Draft content", is_ooc: false } },
        as: :json
      expect(response).to have_http_status(:ok)
      expect(scene.posts.drafts.where(user: player).count).to eq(1)
    end

    it "updates an existing draft" do
      draft = create(:post, :draft, scene: scene, user: player)
      sign_in(player)
      patch save_draft_game_scene_posts_path(game, scene),
        params: { post: { content: "Updated draft", is_ooc: false } },
        as: :json
      expect(response).to have_http_status(:ok)
      expect(draft.reload.content).to eq("Updated draft")
    end

    it "returns unprocessable_content on validation failure" do
      sign_in(player)
      # Create a duplicate draft scenario to trigger validation error
      other_player = create(:user, :with_profile)
      create(:game_member, game: game, user: other_player)
      create(:scene_participant, scene: scene, user: other_player)
      create(:post, :draft, scene: scene, user: player)
      # Force save failure by stubbing
      allow_any_instance_of(Post).to receive(:save).and_return(false)
      patch save_draft_game_scene_posts_path(game, scene),
        params: { post: { content: "x", is_ooc: false } },
        as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /games/:game_id/scenes/:scene_id/posts/discard_draft" do
    it "destroys the draft and redirects" do
      create(:post, :draft, scene: scene, user: player)
      sign_in(player)
      delete discard_draft_game_scene_posts_path(game, scene)
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(scene.posts.drafts.where(user: player).count).to eq(0)
    end

    it "redirects even with no draft" do
      sign_in(player)
      delete discard_draft_game_scene_posts_path(game, scene)
      expect(response).to redirect_to(game_scene_path(game, scene))
    end
  end
end
