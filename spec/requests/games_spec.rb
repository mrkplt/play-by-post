require "rails_helper"

RSpec.describe GamesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /" do
    it "lists only the current user's non-banned games in name order, crowning GM games" do
      alpha_game = create(:game, name: "Alpha Quest")
      zeta_game = create(:game, name: "Zeta Quest")
      banned_game = create(:game, name: "Hidden Game")
      other_users_game = create(:game, name: "Other User Game")

      create(:game_member, game: alpha_game, user: gm)
      create(:game_member, :game_master, game: zeta_game, user: gm)
      create(:game_member, :banned, game: banned_game, user: gm)
      create(:game_member, :game_master, game: other_users_game, user: player)

      sign_in(gm)
      get root_path

      doc = Nokogiri::HTML.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alpha Quest", "Zeta Quest")
      expect(response.body).not_to include("Hidden Game")
      expect(response.body).not_to include("Other User Game")
      expect(response.body.index("Alpha Quest")).to be < response.body.index("Zeta Quest")

      # GM game card carries a crown; the plain player card does not.
      zeta_card = doc.at_xpath("//a[@href='#{game_path(zeta_game)}']")
      alpha_card = doc.at_xpath("//a[@href='#{game_path(alpha_game)}']")
      expect(zeta_card.css("svg, img").count).to be >= 1
      expect(alpha_card.css("svg, img").count).to eq(0)
    end

    it "shows the primary character link and active scene count for each dashboard item" do
      create(:character, game: game, user: gm, name: "Sir Galahad")
      create(:scene, game: game)
      create(:scene, :resolved, game: game)

      sign_in(gm)
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sir Galahad")
      expect(response.body).to include("1 active scene")
    end

    it "shows the first character with +N more count when user has multiple active characters" do
      create(:character, game: game, user: gm, name: "First Knight")
      create(:character, game: game, user: gm, name: "Second Rogue")
      create(:character, game: game, user: gm, name: "Third Wizard")

      sign_in(gm)
      get root_path

      expect(response.body).to include("First Knight")
      expect(response.body).to include("+2")
      expect(response.body).not_to include("Third Wizard")
    end

    it "does not show +N more count with only one active character" do
      create(:character, game: game, user: gm, name: "Solo Hero")

      sign_in(gm)
      get root_path

      expect(response.body).to include("Solo Hero")
      expect(response.body).not_to include("more")
    end

    it "excludes archived characters from the primary character and +N count" do
      create(:character, game: game, user: gm, name: "Active Paladin")
      create(:character, :archived, game: game, user: gm, name: "Retired Ranger")

      sign_in(gm)
      get root_path

      expect(response.body).to include("Active Paladin")
      expect(response.body).not_to include("more")
    end

    it "excludes other players' characters from the +N count" do
      create(:character, game: game, user: gm, name: "My Fighter")
      create(:character, game: game, user: player, name: "Other Cleric")
      create(:character, game: game, user: player, name: "Other Druid")

      sign_in(gm)
      get root_path

      expect(response.body).to include("My Fighter")
      expect(response.body).not_to include("more")
    end

    it "shows a new activity flag only on games with posts since last login" do
      recent_game = create(:game, name: "Recent Game")
      create(:game_member, game: recent_game, user: gm)

      login_as(gm, scope: :user, run_callbacks: false)
      gm.user_profile.update!(last_login_at: 1.hour.ago)

      old_scene = create(:scene, game: game)
      create(:post, scene: old_scene, user: gm, created_at: 2.hours.ago)

      recent_scene = create(:scene, game: recent_game)
      create(:post, scene: recent_scene, user: gm)

      get root_path

      doc = Nokogiri::HTML.parse(response.body)
      recent_card = doc.at_xpath("//a[@href='#{game_path(recent_game)}' and @data-new-activity='true']")
      old_card = doc.at_xpath("//a[@href='#{game_path(game)}' and @data-new-activity='true']")

      expect(doc.css("[data-new-activity='true']").count).to eq(1)
      expect(recent_card).not_to be_nil
      expect(old_card).to be_nil
    end

    it "does not show a new activity flag when the user has no last login timestamp" do
      login_as(gm, scope: :user, run_callbacks: false)
      gm.user_profile.update!(last_login_at: nil)
      scene = create(:scene, game: game)
      create(:post, scene: scene, user: gm)

      get root_path

      doc = Nokogiri::HTML.parse(response.body)

      expect(doc.css("[data-new-activity='true']")).to be_empty
    end

    it "renders empty dashboard for user with no memberships" do
      user = create(:user, :with_profile)
      sign_in(user)

      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the universal header nav affordances with no breadcrumb" do
      sign_in(gm)
      get root_path
      expect_hamburger_present
    end
  end

  describe "GET /games/new" do
    it "renders ok for authenticated user" do
      sign_in(gm)
      get new_game_path
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get new_game_path
      expect(response).to have_http_status(:redirect)
    end

    it "renders the universal header nav affordances with no breadcrumb" do
      sign_in(gm)
      get new_game_path
      expect_hamburger_present
    end
  end

  describe "POST /games" do
    it "creates a game and adds the creator as GM" do
      sign_in(gm)
      expect {
        post games_path, params: { game: { name: "New Adventure" } }
      }.to change(Game, :count).by(1)
      new_game = Game.last
      expect(response).to redirect_to(game_path(new_game))
      expect(new_game.game_master?(gm)).to be true
    end

    it "renders new with unprocessable_content on invalid params" do
      sign_in(gm)
      post games_path, params: { game: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "unauthenticated user is redirected" do
      post games_path, params: { game: { name: "Adventure" } }
      expect(response).to have_http_status(:redirect)
    end

    it "redirects with an alert when the game param is missing" do
      sign_in(gm)
      post games_path, params: {}

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Bad request.")
    end
  end

  describe "GET /games/:id/edit" do
    it "GM can access the edit form" do
      sign_in(gm)
      get edit_game_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get edit_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "unauthenticated user is redirected" do
      get edit_game_path(game)
      expect(response).to have_http_status(:redirect)
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get edit_game_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
    end
  end

  describe "PATCH /games/:id" do
    it "GM can update the game" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "Updated Name" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(game.reload.name).to eq("Updated Name")
    end

    it "GM can update the description" do
      sign_in(gm)
      patch game_path(game), params: { game: { description: "New desc" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(game.reload.description).to eq("New desc")
    end

    it "renders edit on invalid params" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "player cannot update the game" do
      sign_in(player)
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.name).not_to eq("Hacked")
    end

    it "unauthenticated user is redirected" do
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /games/:id" do
    it "GM soft-deletes the game and is redirected to the dashboard" do
      sign_in(gm)
      delete game_path(game)

      expect(response).to redirect_to(root_path)
      expect(Game.unscoped.find(game.id).deleted_at).to be_present
      # The default scope hides it everywhere thereafter.
      expect(Game.exists?(game.id)).to be(false)
    end

    it "player cannot delete the game" do
      sign_in(player)
      delete game_path(game)

      expect(response).to redirect_to(game_path(game))
      expect(Game.unscoped.find(game.id).deleted_at).to be_nil
    end

    it "unauthenticated user is redirected" do
      delete game_path(game)
      expect(response).to have_http_status(:redirect)
    end

    it "leaves a soft-deleted game unreachable" do
      game.soft_delete!
      sign_in(gm)
      get game_path(game)

      expect(response).to redirect_to(root_path)
    end

    it "drops a soft-deleted game from the dashboard" do
      hidden = create(:game, name: "Vanishing Point")
      create(:game_member, :game_master, game: hidden, user: gm)
      hidden.soft_delete!

      sign_in(gm)
      get root_path

      expect(response.body).not_to include("Vanishing Point")
    end
  end

  describe "GET /games/:id" do
    it "renders the universal header nav affordances (hamburger, gear, Scenes active, GM crown)" do
      sign_in(gm)
      get game_path(game)
      expect_hamburger_present
      expect_active_tab("Scenes")
      expect(page_node).to have_css("[href='#{game_player_management_path(game)}']")
      expect(page_node).to have_css("svg, img")
    end

    it "renders the header without a crown icon for a non-GM player" do
      sign_in(player)
      get game_path(game)
      doc = Nokogiri::HTML.parse(response.body)
      header = doc.at_css("header")
      expect(header.inner_html).not_to include("crown")
    end

    it "shows character player email prefix when no display name is set" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      create(:character, game: game, user: player_no_name, name: "Spark")
      sign_in(gm)
      get game_path(game)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "shows character owner display name when set" do
      player.user_profile.update!(display_name: "Frodo Baggins")
      create(:character, game: game, user: player, name: "Ring Bearer")
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Frodo Baggins")
    end

    it "shows active scene titles in the active scenes section" do
      scene = create(:scene, game: game, title: "The Fellowship Meets")
      create(:scene_participant, scene: scene, user: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("The Fellowship Meets")
    end

    it "does not show resolved scene titles in the active scenes section" do
      resolved = create(:scene, :resolved, game: game, title: "Finished Quest")
      create(:scene_participant, scene: resolved, user: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("Finished Quest")
    end

    it "links to the all-scenes view for the GM" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include(game_scenes_path(game))
      expect(response.body).to include("View all scenes")
    end

    it "links to the all-scenes view for a player" do
      sign_in(player)
      get game_path(game)
      expect(response.body).to include(game_scenes_path(game))
      expect(response.body).to include("View all scenes")
    end

    it "does not show private scenes to non-participants in the active scenes section" do
      private_scene = create(:scene, :private, game: game, title: "Secret Council")
      create(:scene_participant, scene: private_scene, user: gm)
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Secret Council")
    end

    it "shows active scenes to participants" do
      public_scene = create(:scene, game: game, title: "Open Battle")
      create(:scene_participant, scene: public_scene, user: player)
      sign_in(player)
      get game_path(game)
      expect(response.body).to include("Open Battle")
    end

    it "does not show archived characters in the character roster" do
      archived = create(:character, :archived, game: game, user: player, name: "Retired Hero")
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("Retired Hero")
    end

    it "notes the number of hidden inactive characters" do
      create(:character, :archived, game: game, user: player, name: "Retired Hero")
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("1 inactive character")
    end

    it "dims a removed player's character row with a Removed badge and muted avatar" do
      removed_player = create(:user, :with_profile)
      create(:game_member, :removed, game: game, user: removed_player)
      create(:character, game: game, user: removed_player, name: "Ghost Knight")
      create(:character, game: game, user: player, name: "Bright Squire")
      sign_in(gm)
      get game_path(game)

      doc = Nokogiri::HTML.parse(response.body)
      removed_row = doc.xpath("//div[@data-roster-name][contains(., 'Ghost Knight')]").first.to_html
      active_row  = doc.xpath("//div[@data-roster-name][contains(., 'Bright Squire')]").first.to_html

      # Removed → dimmed, muted avatar tone, and a "Removed" badge.
      expect(removed_row).to include("opacity-70")
      expect(removed_row).to include(Ui::AvatarComponent::TONES.fetch(:muted))
      expect(removed_row).to include("Removed")
      # Active → none of those; gold avatar tone.
      expect(active_row).not_to include("opacity-70")
      expect(active_row).to include(Ui::AvatarComponent::TONES.fetch(:gold))
      expect(active_row).not_to include("Removed")
    end

    it "builds a lowercased search filter key from character and owner names" do
      player.user_profile.update!(display_name: "Sam Gamgee")
      create(:character, game: game, user: player, name: "Frodo")
      sign_in(gm)
      get game_path(game)

      doc = Nokogiri::HTML.parse(response.body)
      keys = doc.xpath("//*[@data-roster-name]/@data-roster-name").map(&:value)
      expect(keys).to include("frodo sam gamgee")
    end

    it "shows the GM-only Banned section listing banned players" do
      banned_player = create(:user, :with_profile)
      banned_player.user_profile.update!(display_name: "Exiled One")
      create(:game_member, :banned, game: game, user: banned_player)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Exiled One")
    end

    it "does not expose banned players to a non-GM member" do
      banned_player = create(:user, :with_profile)
      banned_player.user_profile.update!(display_name: "Exiled One")
      create(:game_member, :banned, game: game, user: banned_player)
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Exiled One")
    end

    it "renders the invite form on the roster for the GM" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Invite a Player")
      expect(response.body).to include("name=\"invitation[email]\"")
    end

    it "does not render the invite form for a non-GM member" do
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Invite a Player")
    end

    it "shows a pending invitation email to the GM on the roster" do
      create(:invitation, game: game, email: "invited@example.com", invited_by: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("invited@example.com")
    end

    it "does not show an accepted invitation in the roster pending list" do
      create(:invitation, :accepted, game: game, email: "accepted@example.com", invited_by: gm)
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("accepted@example.com")
    end

    it "shows pending invitations newest first" do
      create(:invitation, game: game, email: "older@example.com", invited_by: gm, created_at: 2.days.ago)
      create(:invitation, game: game, email: "newer@example.com", invited_by: gm, created_at: 1.day.ago)
      sign_in(gm)
      get game_path(game)
      older_pos = response.body.index("older@example.com")
      newer_pos = response.body.index("newer@example.com")
      expect(newer_pos).to be < older_pos
    end

    it "does not expose pending invitations to a non-GM member" do
      create(:invitation, game: game, email: "invited@example.com", invited_by: gm)
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("invited@example.com")
    end

    it "does not show the Export Game button on the game view (it lives on the settings page)" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).not_to include("Export Game")
    end

    it "shows GM management controls for GM" do
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("New Scene")
    end

    it "does not show New Scene button to non-GM player" do
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("New Scene")
    end

    it "shows characters in alphabetical order" do
      create(:character, game: game, user: player, name: "Zara the Bold")
      create(:character, game: game, user: player, name: "Aaron the Swift")
      sign_in(gm)
      get game_path(game)
      aaron_pos = response.body.index("Aaron the Swift")
      zara_pos = response.body.index("Zara the Bold")
      expect(aaron_pos).to be < zara_pos
    end

    it "does not show hidden characters to a non-owner player" do
      other = create(:user, :with_profile)
      create(:game_member, game: game, user: other)
      create(:character, :hidden, game: game, user: other, name: "Secret Character")
      sign_in(player)
      get game_path(game)
      expect(response.body).not_to include("Secret Character")
    end

    it "shows scenes sorted by most recent activity first" do
      older_scene = create(:scene, game: game, title: "Older Scene Title")
      create(:scene_participant, scene: older_scene, user: gm)
      create(:post, scene: older_scene, user: gm, created_at: 2.days.ago)

      newer_scene = create(:scene, game: game, title: "Newer Scene Title")
      create(:scene_participant, scene: newer_scene, user: gm)
      create(:post, scene: newer_scene, user: gm, created_at: 1.hour.ago)

      sign_in(gm)
      get game_path(game)
      older_pos = response.body.index("Older Scene Title")
      newer_pos = response.body.index("Newer Scene Title")
      expect(newer_pos).to be < older_pos
    end

    it "shows the GM by display name in the roster preview with 'Running this game'" do
      gm.user_profile.update!(display_name: "Gandalf the Grey")
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Gandalf the Grey")
      expect(response.body).to include("Running this game")
    end

    it "falls back to 'GM' in the roster preview when no GM record resolves a name" do
      gm.user_profile.update!(display_name: nil)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Running this game")
    end

    it "lists a participating character and its scene in the roster preview" do
      char = create(:character, game: game, user: player, name: "Aragorn")
      scene = create(:scene, game: game, title: "The Council")
      create(:scene_participant, scene: scene, user: player, character: char)
      sign_in(gm)
      get game_path(game)
      expect(response.body).to include("Aragorn")
      expect(response.body).to include("The Council")
    end

    it "glows a scene with activity since last login but not an older one" do
      login_as(gm, scope: :user, run_callbacks: false)
      gm.user_profile.update!(last_login_at: 1.hour.ago)

      hot = create(:scene, game: game, title: "Hot Scene")
      create(:scene_participant, scene: hot, user: gm)
      create(:post, scene: hot, user: gm, created_at: 5.minutes.ago)

      cold = create(:scene, game: game, title: "Cold Scene")
      create(:scene_participant, scene: cold, user: gm)
      create(:post, scene: cold, user: gm, created_at: 2.days.ago)

      get game_path(game)
      doc = Nokogiri::HTML.parse(response.body)
      hot_card = doc.at_xpath("//a[normalize-space()='Hot Scene']/ancestor-or-self::*[contains(@class,'is-hot')]")
      cold_card = doc.at_xpath("//a[normalize-space()='Cold Scene']/ancestor-or-self::*[contains(@class,'is-hot')]")
      expect(hot_card).not_to be_nil
      expect(cold_card).to be_nil
    end

    it "does not glow any scene when the user has never logged in" do
      login_as(gm, scope: :user, run_callbacks: false)
      gm.user_profile.update!(last_login_at: nil)
      scene = create(:scene, game: game, title: "Some Scene")
      create(:scene_participant, scene: scene, user: gm)
      create(:post, scene: scene, user: gm)

      get game_path(game)
      expect(response.body).not_to include("is-hot")
    end
  end

  describe "PATCH /games/:id/toggle_sheets_hidden" do
    it "GM can hide character sheets" do
      sign_in(gm)
      patch toggle_sheets_hidden_game_path(game)
      expect(game.reload.sheets_hidden?).to be true
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to match(/hidden/i)
    end

    it "GM can reveal character sheets" do
      game.update!(sheets_hidden: true)
      sign_in(gm)
      patch toggle_sheets_hidden_game_path(game)
      expect(game.reload.sheets_hidden?).to be false
      expect(flash[:notice]).to match(/visible/i)
    end

    it "player cannot toggle character sheet visibility" do
      sign_in(player)
      patch toggle_sheets_hidden_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.sheets_hidden?).to be false
    end
  end

  describe "require_game_access! — banned user" do
    let(:banned_user) { create(:user, :with_profile) }

    before do
      create(:game_member, :banned, game: game, user: banned_user)
    end

    it "redirects to root with alert on show" do
      sign_in(banned_user)
      get game_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
    end
  end

  describe "PATCH /games/:id/toggle_ai_summaries_enabled" do
    it "GM can enable AI summaries" do
      sign_in(gm)
      patch toggle_ai_summaries_enabled_game_path(game)
      expect(game.reload.ai_summaries_enabled?).to be true
      expect(response).to redirect_to(game_player_management_path(game))
      expect(flash[:notice]).to match(/enabled/i)
    end

    it "GM can disable AI summaries" do
      game.update!(ai_summaries_enabled: true)
      sign_in(gm)
      patch toggle_ai_summaries_enabled_game_path(game)
      expect(game.reload.ai_summaries_enabled?).to be false
      expect(response).to redirect_to(game_player_management_path(game))
      expect(flash[:notice]).to match(/disabled/i)
    end

    it "player cannot toggle AI summaries" do
      sign_in(player)
      patch toggle_ai_summaries_enabled_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.ai_summaries_enabled?).to be false
    end
  end

  describe "PATCH /games/:id/toggle_images_disabled" do
    it "GM can disable image attachments" do
      sign_in(gm)
      patch toggle_images_disabled_game_path(game)
      expect(game.reload.images_disabled?).to be true
      expect(response).to redirect_to(edit_game_path(game))
      expect(flash[:notice]).to match(/disabled/i)
    end

    it "GM can re-enable image attachments" do
      game.update!(images_disabled: true)
      sign_in(gm)
      patch toggle_images_disabled_game_path(game)
      expect(game.reload.images_disabled?).to be false
      expect(response).to redirect_to(edit_game_path(game))
      expect(flash[:notice]).to match(/enabled/i)
    end

    it "player cannot toggle image attachments" do
      sign_in(player)
      patch toggle_images_disabled_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.images_disabled?).to be false
    end
  end
end
