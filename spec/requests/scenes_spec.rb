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

    it "shows New Scene link to GM" do
      sign_in(gm)
      get game_scenes_path(game)
      expect(response.body).to include("New Scene")
    end

    it "does not show New Scene link to player" do
      sign_in(player)
      get game_scenes_path(game)
      expect(response.body).not_to include("New Scene")
    end

    it "shows scene titles in the tree" do
      create(:scene, game: game, title: "Epic Battle Scene")
      sign_in(gm)
      get game_scenes_path(game)
      expect(response.body).to include("Epic Battle Scene")
    end

    it "shows No scenes yet when game has no scenes" do
      sign_in(gm)
      get game_scenes_path(game)
      expect(response.body).to include("No scenes yet")
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

    it "shows active player display names in the participants section" do
      player.user_profile.update!(display_name: "Epic Player")
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).to include("Epic Player")
    end

    it "shows player email prefix when no display name in participants section" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "does not show removed players in the participants section" do
      removed = create(:user, :with_profile)
      removed.user_profile.update!(display_name: "Former Member")
      create(:game_member, :removed, game: game, user: removed)
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).not_to include("Former Member")
    end

    it "shows character names for player selection" do
      character = create(:character, game: game, user: player, name: "Ranger of the North")
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).to include("Ranger of the North")
    end

    it "does not show inactive characters in the participants section" do
      create(:character, :archived, game: game, user: player, name: "Retired Ranger")
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).not_to include("Retired Ranger")
    end

    it "does not show the GM as a selectable participant" do
      create(:character, game: game, user: player, name: "Player Hero")
      sign_in(gm)
      get new_game_scene_path(game)
      expect(response.body).not_to include("No active characters")
    end

    it "shows players in alphabetical order by display name" do
      player.user_profile.update!(display_name: "Zelda Zephyr")
      player2 = create(:user)
      create(:game_member, game: game, user: player2)
      create(:user_profile, user: player2, display_name: "Aaron Aardvark")
      sign_in(gm)
      get new_game_scene_path(game)
      aaron_pos = response.body.index("Aaron Aardvark")
      zelda_pos = response.body.index("Zelda Zephyr")
      expect(aaron_pos).to be < zelda_pos
    end

    it "shows characters in alphabetical order under each player" do
      create(:character, game: game, user: player, name: "Zara the Fierce")
      create(:character, game: game, user: player, name: "Aaron the Brave")
      sign_in(gm)
      get new_game_scene_path(game)
      aaron_pos = response.body.index("Aaron the Brave")
      zara_pos = response.body.index("Zara the Fierce")
      expect(aaron_pos).to be < zara_pos
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

    it "renders post author names from post_presenters" do
      nameless = create(:user)
      create(:game_member, game: game, user: nameless)
      create(:scene_participant, scene: scene, user: nameless)
      create(:post, scene: scene, user: nameless)
      sign_in(gm)
      get game_scene_path(game, scene)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(nameless.email)
    end

    context "GM-specific content (@is_gm)" do
      it "shows Edit Participants link to GM" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Edit Participants")
      end

      it "does not show Edit Participants link to non-GM player" do
        create(:scene_participant, scene: scene, user: player)
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("Edit Participants")
      end

      it "shows resolve form only to GM" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("End Scene")
      end

      it "does not show resolve form to player" do
        create(:scene_participant, scene: scene, user: player)
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("End Scene")
      end
    end

    context "notification mute toggle (@is_muted)" do
      it "shows Mute notifications when not muted" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Mute notifications")
      end

      it "shows Unmute notifications when muted" do
        create(:notification_preference, scene: scene, user: gm, muted: true)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Unmute notifications")
      end
    end

    context "hide_ooc data attribute (@hide_ooc)" do
      it "sets hide-ooc-value to false by default" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include('data-ooc-filter-hide-ooc-value="false"')
      end

      it "sets hide-ooc-value to true when user has hide_ooc enabled" do
        gm.user_profile.update!(hide_ooc: true)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include('data-ooc-filter-hide-ooc-value="true"')
      end

      it "sets hide-ooc-value to false when user has no profile" do
        user_no_profile = create(:user)
        create(:game_member, game: game, user: user_no_profile)
        create(:scene_participant, scene: scene, user: user_no_profile)
        sign_in(user_no_profile)
        get game_scene_path(game, scene)
        expect(response.body).to include('data-ooc-filter-hide-ooc-value="false"')
      end
    end

    context "post composer visibility (@is_participant, @is_gm)" do
      it "shows post composer to GM" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("post_composer")
      end

      it "shows post composer to a participant" do
        create(:scene_participant, scene: scene, user: player)
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).to include("post_composer")
      end

      it "does not show post composer to non-participant player" do
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("post_composer")
      end
    end

    context "join scene button (@is_participant, @current_membership)" do
      it "shows Join Scene to active non-participant player" do
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).to include("Join Scene")
      end

      it "does not show Join Scene to a participant" do
        create(:scene_participant, scene: scene, user: player)
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("Join Scene")
      end

      it "does not show Join Scene to GM" do
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("Join Scene")
      end
    end

    context "draft recovery (@draft)" do
      it "shows draft recovery notice on resolved scene when draft exists" do
        resolved_scene = create(:scene, :resolved, game: game)
        create(:scene_participant, scene: resolved_scene, user: gm)
        create(:post, :draft, scene: resolved_scene, user: gm, content: "My unfinished post")
        sign_in(gm)
        get game_scene_path(game, resolved_scene)
        expect(response.body).to include("unsaved draft")
      end

      it "does not show draft recovery on active scene" do
        create(:post, :draft, scene: scene, user: gm, content: "Draft content")
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("unsaved draft")
      end

      it "does not show draft notice on resolved scene when only published posts exist" do
        resolved_scene = create(:scene, :resolved, game: game)
        create(:scene_participant, scene: resolved_scene, user: gm)
        create(:post, scene: resolved_scene, user: gm, content: "Published content")
        sign_in(gm)
        get game_scene_path(game, resolved_scene)
        expect(response.body).not_to include("unsaved draft")
      end
    end

    context "last_visited_at update" do
      it "updates last_visited_at to current time for the current user's scene participant" do
        sp = SceneParticipant.find_by!(scene: scene, user: gm)
        sp.update!(last_visited_at: 1.hour.ago)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(sp.reload.last_visited_at).to be_within(5.seconds).of(Time.current)
      end

      it "does not update last_visited_at for other participants" do
        create(:scene_participant, scene: scene, user: player)
        player_sp = SceneParticipant.find_by!(scene: scene, user: player)
        player_sp.update!(last_visited_at: 2.hours.ago)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(player_sp.reload.last_visited_at).to be_within(1.minute).of(2.hours.ago)
      end
    end

    context "child scenes (@child_scenes)" do
      it "shows child scenes in the response" do
        child = create(:scene, game: game, parent_scene: scene, title: "Child Thread")
        create(:scene_participant, scene: child, user: gm)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Child Thread")
      end

      it "does not show private child scenes to non-participants" do
        private_child = create(:scene, :private, game: game, parent_scene: scene, title: "Secret Thread")
        sign_in(player)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("Secret Thread")
      end
    end

    context "only published posts appear (@posts with .published)" do
      it "does not show another user's draft post in the response" do
        # player's draft should not appear even in composer (only current user's draft shows)
        create(:post, :draft, scene: scene, user: player, content: "Draft content only")
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).not_to include("Draft content only")
      end

      it "shows published posts" do
        create(:post, scene: scene, user: gm, content: "Published content here")
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Published content here")
      end
    end

    context "resolved scene (@read_post_ids is empty Set)" do
      it "renders the resolved badge for a resolved scene" do
        resolved_scene = create(:scene, :resolved, game: game)
        create(:scene_participant, scene: resolved_scene, user: gm)
        sign_in(gm)
        get game_scene_path(game, resolved_scene)
        expect(response.body).to include("Resolved")
      end
    end

    context "@post_presenters with scene participants" do
      it "shows character name when post is by a character participant" do
        character = create(:character, game: game, user: player, name: "Gandalf")
        create(:scene_participant, scene: scene, user: player, character: character)
        create(:post, scene: scene, user: player)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include("Gandalf")
      end
    end

    context "read post tracking (@read_post_ids via PostRead)" do
      it "marks a recently-read post as not unread" do
        post_record = create(:post, scene: scene, user: player)
        create(:post_read, post: post_record, user: gm)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include('data-unread="false"')
      end

      it "marks a recent post without a PostRead as unread" do
        create(:post, scene: scene, user: player)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body).to include('data-unread="true"')
      end
    end

    context "posts appear in chronological order" do
      it "renders older posts before newer posts" do
        create(:post, scene: scene, user: gm, content: "Older Post Alpha", created_at: 2.hours.ago)
        create(:post, scene: scene, user: gm, content: "Newer Post Beta", created_at: 1.hour.ago)
        sign_in(gm)
        get game_scene_path(game, scene)
        expect(response.body.index("Older Post Alpha")).to be < response.body.index("Newer Post Beta")
      end
    end
  end

  describe "POST /games/:game_id/scenes (create error path)" do
    it "re-renders new with parent scene options wrapped as presenters on validation failure" do
      resolved_parent = create(:scene, :resolved, game: game, title: "Ended Saga")
      sign_in(gm)
      long_title = "a" * 201
      post game_scenes_path(game), params: { scene: { title: long_title } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Ended Saga (Resolved)")
    end

    it "shows active scenes in parent options on validation failure" do
      active_parent = create(:scene, game: game, title: "Active Saga")
      sign_in(gm)
      long_title = "a" * 201
      post game_scenes_path(game), params: { scene: { title: long_title } }
      expect(response.body).to include("Active Saga")
    end
  end

  describe "POST /games/:game_id/scenes" do
    it "GM can create a scene" do
      sign_in(gm)
      expect {
        post game_scenes_path(game), params: { scene: { title: "Test Scene" } }
      }.to change(Scene, :count).by(1)
      expect(response).to redirect_to(game_scene_path(game, Scene.last))
      expect(flash[:notice]).to eq("Scene created.")
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
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:notice]).to eq("Scene resolved.")
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
