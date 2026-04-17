require "rails_helper"

RSpec.describe ScenesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:game_id/scenes (index)" do
    it "GM can access the scene index" do
      sign_in(gm)
      get game_scenes_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player can access the scene index" do
      sign_in(player)
      get game_scenes_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get game_scenes_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /games/:game_id/scenes/new" do
    it "GM can access the new scene form" do
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get new_game_scene_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "shows resolved scene with (Resolved) suffix in parent options" do
      resolved = create(:scene, :resolved, game: game, title: "Old Thread")
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).to include("Old Thread (Resolved)")
    end
  end

  describe "GET /games/:game_id/scenes/:id" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
    end

    it "renders ok for a GM" do
      sign_in(gm)
      get game_scene_path(game, scene)
      expect(response).to have_http_status(:ok)
    end

    it "renders ok for a participant" do
      create(:scene_participant, scene: scene, user: player)
      sign_in(player)
      get game_scene_path(game, scene)
      expect(response).to have_http_status(:ok)
    end

    it "shows participant names via scene_presenter" do
      character = create(:character, game: game, user: player, name: "Drax")
      create(:scene_participant, scene: scene, user: player, character: character)
      sign_in(gm)
      get game_scene_path(game, scene)
      expect(response.body).to include("Drax")
    end

    it "shows post author names via post_presenters" do
      create(:scene_participant, scene: scene, user: player)
      post_record = create(:post, scene: scene, user: player)
      sign_in(gm)
      get game_scene_path(game, scene)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post_record.user.email.split("@").first)
    end
  end

  describe "POST /games/:game_id/scenes" do
    it "GM can create a scene" do
      sign_in(gm)
      expect {
        post game_scenes_path(game), params: { scene: { title: "Test" } }
      }.to change(Scene, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "automatically adds the GM as a participant" do
      sign_in(gm)
      post game_scenes_path(game), params: { scene: { title: "New Scene" } }
      scene = Scene.last
      expect(scene.scene_participants.where(user: gm)).to exist
    end

    it "adds character participants when character_ids provided" do
      character = create(:character, game: game, user: player)
      sign_in(gm)
      post game_scenes_path(game), params: { scene: { title: "With Players" }, character_ids: [ character.id ] }
      scene = Scene.last
      sp = scene.scene_participants.find_by(user: player)
      expect(sp).not_to be_nil
      expect(sp.character).to eq(character)
    end

    it "GM can create a scene with blank title (gets default)" do
      sign_in(gm)
      post game_scenes_path(game), params: { scene: { title: "" } }
      expect(Scene.last.title).to match(/\A\w+ \d+, \d{4}/)
    end

    it "player cannot create a scene" do
      sign_in(player)
      expect {
        post game_scenes_path(game), params: { scene: { title: "Sneaky" } }
      }.not_to change(Scene, :count)
      expect(response).to redirect_to(game_path(game))
    end

    context "email notifications" do
      around do |example|
        original_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test
        example.run
        ActiveJob::Base.queue_adapter = original_adapter
      end

      it "enqueues a new_scene notification email to participants but not the creator" do
        character = create(:character, game: game, user: player)
        sign_in(gm)

        post game_scenes_path(game), params: { scene: { title: "Email Test Scene" }, character_ids: [ character.id ] }

        mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
          j["job_class"] == "ActionMailer::MailDeliveryJob" &&
          j["arguments"]&.first == "NotificationMailer" &&
          j["arguments"]&.second == "new_scene"
        }
        expect(mail_jobs.size).to eq(1)
        recipient_gid = mail_jobs.first["arguments"][3]["args"][1]["_aj_globalid"]
        expect(recipient_gid).to include("User/#{player.id}")
        expect(recipient_gid).not_to include("User/#{gm.id}")
      end

      it "does not enqueue a new_scene email when the GM is the only participant" do
        sign_in(gm)

        post game_scenes_path(game), params: { scene: { title: "Solo Scene" } }

        mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
          j["job_class"] == "ActionMailer::MailDeliveryJob" &&
          j["arguments"]&.first == "NotificationMailer" &&
          j["arguments"]&.second == "new_scene"
        }
        expect(mail_jobs).to be_empty
      end
    end
  end

  describe "PATCH /games/:game_id/scenes/:id/resolve" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
    end

    it "GM can resolve a scene" do
      sign_in(gm)
      patch resolve_game_scene_path(game, scene), params: { resolution: "Done." }
      expect(scene.reload).to be_resolved
    end

    it "player cannot resolve a scene" do
      create(:scene_participant, scene: scene, user: player)
      sign_in(player)
      patch resolve_game_scene_path(game, scene), params: { resolution: "Nope." }
      expect(scene.reload).not_to be_resolved
      expect(response).to redirect_to(game_scene_path(game, scene))
    end

    context "email notifications" do
      around do |example|
        original_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test
        example.run
        ActiveJob::Base.queue_adapter = original_adapter
      end

      it "enqueues scene_resolved notification emails to all participants" do
        create(:scene_participant, scene: scene, user: player)
        sign_in(gm)

        patch resolve_game_scene_path(game, scene), params: { resolution: "All wrapped up." }

        mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
          j["job_class"] == "ActionMailer::MailDeliveryJob" &&
          j["arguments"]&.first == "NotificationMailer" &&
          j["arguments"]&.second == "scene_resolved"
        }
        expect(mail_jobs.size).to eq(2)
        recipient_gids = mail_jobs.map { |j| j["arguments"][3]["args"][1]["_aj_globalid"] }
        expect(recipient_gids).to include(a_string_including("User/#{gm.id}"))
        expect(recipient_gids).to include(a_string_including("User/#{player.id}"))
      end
    end
  end
end
