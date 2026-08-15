require "rails_helper"

RSpec.describe Posts::DraftsController, type: :request do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:author) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }

  before do
    create(:game_member, game: game, user: author)
    create(:scene_participant, scene: scene, user: author)
  end

  describe "PATCH save_draft" do
    it "saves a draft and returns its id" do
      sign_in author

      patch save_draft_game_scene_posts_path(game, scene), params: { post: { content: "Half a thought" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(scene.posts.drafts.sole.id)
    end

    # A draft is autosaved as the user types, so an empty one is a legitimate
    # state rather than a validation failure.
    it "accepts an empty draft" do
      sign_in author

      patch save_draft_game_scene_posts_path(game, scene), params: { post: { content: "" } }

      expect(response).to have_http_status(:ok)
    end

    it "updates the existing draft rather than creating a second" do
      sign_in author
      patch save_draft_game_scene_posts_path(game, scene), params: { post: { content: "First" } }

      expect { patch save_draft_game_scene_posts_path(game, scene), params: { post: { content: "Second" } } }
        .not_to change { scene.posts.drafts.count }
      expect(scene.posts.drafts.sole.content).to eq("Second")
    end

    it "turns a non-participant away" do
      sign_in outsider

      patch save_draft_game_scene_posts_path(game, scene), params: { post: { content: "Hello" } }

      expect(scene.posts.drafts).to be_empty
    end
  end

  describe "DELETE discard_draft" do
    it "discards the draft and returns to the scene" do
      create(:post, scene: scene, user: author, draft: true)
      sign_in author

      delete discard_draft_game_scene_posts_path(game, scene)

      expect(scene.posts.drafts).to be_empty
      expect(response).to redirect_to(game_scene_path(game, scene))
    end

    it "does not discard another participant's draft" do
      other = create(:user, :with_profile)
      create(:game_member, game: game, user: other)
      create(:scene_participant, scene: scene, user: other)
      theirs = create(:post, scene: scene, user: other, draft: true)
      sign_in author

      delete discard_draft_game_scene_posts_path(game, scene)

      expect(theirs.reload).to be_persisted
    end
  end
end
