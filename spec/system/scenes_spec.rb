require "rails_helper"

RSpec.describe "Scenes", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "scene creation (GM only)" do
    before { sign_in_as(gm) }

    it "creates a scene with a title" do
      visit game_path(game)
      click_on "New Scene"

      fill_in "Title", with: "The Tavern Encounter"
      click_on "Create Scene"

      expect(page).to have_text("The Tavern Encounter")
    end

    it "creates a scene with default datetime title when title is blank" do
      visit game_path(game)
      click_on "New Scene"
      click_on "Create Scene"

      expect(page).to have_text("Scene created.")
      expect(page).to have_text(Time.current.strftime("%Y"))
    end

    it "includes the GM as a participant automatically" do
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "GM Solo Scene"
      click_on "Create Scene"

      expect(page).to have_text(gm.display_name)
    end

    it "allows selecting characters as participants" do
      character = create(:character, game: game, user: player, name: "Seraphina Vex")
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "Group Scene"
      check character.name
      click_on "Create Scene"

      expect(page).to have_text(character.name)
    end

    it "can create a private scene" do
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "Secret Scene"
      check "Private scene"
      click_on "Create Scene"

      expect(page).to have_text("Private")
    end

    it "shows only active scenes and 3 most recently resolved in parent dropdown" do
      active1 = create(:scene, game: game, title: "Active One")
      active2 = create(:scene, game: game, title: "Active Two")
      old_resolved = create(:scene, :resolved, game: game, title: "Old Resolved", resolved_at: 4.days.ago)
      r1 = create(:scene, :resolved, game: game, title: "Recent Resolved 1", resolved_at: 3.days.ago)
      r2 = create(:scene, :resolved, game: game, title: "Recent Resolved 2", resolved_at: 2.days.ago)
      r3 = create(:scene, :resolved, game: game, title: "Recent Resolved 3", resolved_at: 1.day.ago)

      visit new_game_scene_path(game)

      expect(page).to have_select("Parent scene", with_options: [
        "Active One", "Active Two",
        "Recent Resolved 1 (Resolved)", "Recent Resolved 2 (Resolved)", "Recent Resolved 3 (Resolved)"
      ])
      expect(page).not_to have_select("Parent scene", with_options: ["Old Resolved (Resolved)"])
    end
  end

  describe "scene creation denied for players" do
    before { sign_in_as(player) }

    it "does not show New Scene button on game view" do
      visit game_path(game)

      expect(page).not_to have_link("New Scene")
    end

    it "redirects player who visits scene creation URL directly" do
      visit new_game_scene_path(game)

      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("Only the GM can create scenes")
    end
  end

  describe "quick scene" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
      sign_in_as(gm)
    end

    it "creates a quick scene inheriting the parent" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Quick Scene"

      fill_in "Title", with: "Continuation"
      click_on "Create Quick Scene"

      expect(page).to have_text("Continuation")
      expect(page).to have_text("Continues from #{scene.title}")
    end

    it "player does not see Quick Scene in menu" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      if page.has_button?("Scene actions", wait: 1)
        find("button[title='Scene actions']").click
        expect(page).not_to have_link("Quick Scene")
      end
    end
  end

  describe "scene view" do
    let(:scene) { create(:scene, game: game, title: "The Bridge") }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
    end

    it "shows scene title and participants" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).to have_text("The Bridge")
      expect(page).to have_text(player.display_name)
      expect(page).to have_text(gm.display_name)
    end

    it "shows private badge for private scenes" do
      scene.update!(private: true)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).to have_text("Private")
    end

    it "shows parent scene link when scene has a parent" do
      parent = create(:scene, game: game, title: "The Road")
      scene.update!(parent_scene: parent)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).to have_text("Continues from")
      expect(page).to have_link("The Road")
    end

    it "hides private scene from non-participants" do
      scene.update!(private: true)
      outsider = create(:user, :with_profile)
      create(:game_member, game: game, user: outsider)
      sign_in_as(outsider)

      visit game_scene_path(game, scene)

      expect(page).to have_current_path(game_path(game))
    end

    it "shows child scenes" do
      child = create(:scene, game: game, title: "The Fortress", parent_scene: scene)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).to have_link("The Fortress")
    end
  end

  describe "scene menu actions (GM only)" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
    end

    it "GM sees Quick Scene, New Scene, Edit Participants, and End Scene" do
      sign_in_as(gm)
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click

      expect(page).to have_link("Quick Scene")
      expect(page).to have_link("New Scene")
      expect(page).to have_link("Edit Participants")
      expect(page).to have_button("End Scene")
    end

    it "player does not see GM-only menu items" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      if page.has_button?("Scene actions", wait: 1)
        find("button[title='Scene actions']").click
        expect(page).not_to have_link("Quick Scene")
        expect(page).not_to have_link("New Scene")
        expect(page).not_to have_link("Edit Participants")
        expect(page).not_to have_button("End Scene")
      end
    end
  end

  describe "edit participants (GM only)" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
    end

    it "player cannot access edit participants directly" do
      sign_in_as(player)
      visit edit_game_scene_participants_path(game, scene)

      expect(page).to have_current_path(game_scene_path(game, scene))
      expect(page).to have_text("Only the GM can edit participants")
    end

    it "GM can access edit participants" do
      create(:character, game: game, user: player, name: "Vex")
      sign_in_as(gm)
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Edit Participants"

      expect(page).to have_text("Vex")
    end
  end

  describe "scene resolution" do
    let(:scene) { create(:scene, game: game, title: "The Final Battle") }

    before do
      create(:scene_participant, scene: scene, user: gm)
      sign_in_as(gm)
    end

    it "GM can resolve a scene with outcome text" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "End Scene"
      fill_in "Outcome (optional)", with: "The party defeated the dragon."
      click_on "Confirm — End Scene"

      expect(page).to have_text("Resolved")
      expect(page).to have_text("The party defeated the dragon.")
    end

    it "hides the scene actions menu after resolution" do
      scene.update!(resolved_at: Time.current, resolution: "Done.")
      visit game_scene_path(game, scene)

      expect(page).not_to have_css("button[title='Scene actions']")
    end

    it "resolved scene no longer shows the composer" do
      scene.update!(resolved_at: Time.current, resolution: "Done.")
      visit game_scene_path(game, scene)

      expect(page).not_to have_css("#post_composer")
    end

    it "player cannot see the End Scene button" do
      create(:scene_participant, scene: scene, user: player)
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("End Scene")
    end
  end

  describe "notification mute" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      sign_in_as(gm)
    end

    it "can mute and unmute notifications for a scene" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Mute notifications"

      expect(page).to have_text("Notifications muted")

      find("button[title='Scene actions']").click
      click_on "Unmute notifications"

      expect(page).to have_text("Notifications enabled")
    end

    it "muting via UI suppresses digest emails" do
      create(:scene_participant, scene: scene, user: player)
      scene.scene_participants.find_by(user: gm).update!(last_visited_at: 2.days.ago)
      create(:post, scene: scene, user: player, content: "New activity while GM away")

      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Mute notifications"

      expect(page).to have_text("Notifications muted")
      expect(NotificationPreference.muted?(scene, gm)).to be true

      ActiveJob::Base.queue_adapter = :test
      PostDigestJob.perform_now

      digest_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
        j["job_class"] == "ActionMailer::MailDeliveryJob" &&
        j["arguments"]&.first == "NotificationMailer" &&
        j["arguments"]&.second == "post_digest"
      }
      expect(digest_jobs).to be_empty
    end
  end

  describe "join scene" do
    let(:scene) { create(:scene, game: game, title: "Open Adventure") }
    let(:joiner) { create(:user, :with_profile) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:game_member, game: game, user: joiner)
    end

    it "active player can join a non-private scene" do
      sign_in_as(joiner)
      visit game_scene_path(game, scene)

      click_on "Join Scene"

      expect(page).to have_text("You have joined this scene.")
      expect(page).to have_text(joiner.display_name)
    end

    it "does not show Join Scene button to existing participants" do
      create(:scene_participant, scene: scene, user: player)
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("Join Scene")
    end

    it "does not show Join Scene button on resolved scenes" do
      scene.update!(resolved_at: Time.current, resolution: "Done.")
      sign_in_as(joiner)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("Join Scene")
    end

    it "does not show Join Scene button to GM" do
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("Join Scene")
    end

    it "does not show Join Scene button on private scenes" do
      scene.update!(private: true)
      # Private scenes redirect non-participants, so joiner can't even see it
      sign_in_as(joiner)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("Join Scene")
    end
  end

  describe "all scenes (DAG tree view)" do
    it "shows the scene tree with hierarchy" do
      root = create(:scene, :resolved, game: game, title: "The Beginning")
      child = create(:scene, game: game, title: "The Middle", parent_scene: root)
      grandchild = create(:scene, game: game, title: "The End", parent_scene: child)

      sign_in_as(gm)
      visit game_scenes_path(game)

      expect(page).to have_text("All Scenes")
      expect(page).to have_link("The Beginning")
      expect(page).to have_link("The Middle")
      expect(page).to have_link("The End")
      expect(page).to have_text("Active").or have_css(".badge--green")
      expect(page).to have_text("Resolved").or have_css(".badge--gray")
    end

    it "shows New Scene button for GM only" do
      sign_in_as(gm)
      visit game_scenes_path(game)
      expect(page).to have_link("New Scene")

      sign_in_as(player)
      visit game_scenes_path(game)
      expect(page).not_to have_link("New Scene")
    end

    it "shows branching scenes" do
      root = create(:scene, :resolved, game: game, title: "Branch Point")
      branch_a = create(:scene, game: game, title: "Branch A", parent_scene: root)
      branch_b = create(:scene, game: game, title: "Branch B", parent_scene: root)

      sign_in_as(gm)
      visit game_scenes_path(game)

      expect(page).to have_link("Branch Point")
      expect(page).to have_link("Branch A")
      expect(page).to have_link("Branch B")
    end
  end
end
