require "rails_helper"

RSpec.describe "Profiles", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before { sign_in_as(user) }

  describe "display name (inline edit)" do
    ViewportHelper::VIEWPORTS.each do |label, (width, height)|
      context "at #{label}" do
        before { resize_window_to_viewport(width, height) }

        it "edits in place with no navigation and shows a confirmation toast" do
          visit profile_path

          # Tag a node outside the swapped control. A full page reload (Turbo
          # Drive rebuilding <body> from fresh server HTML) drops this
          # attribute; a targeted Turbo Stream swap of just the control leaves
          # it — its survival proves this stayed in place.
          page.execute_script(
            "document.querySelector('main, body').setAttribute('data-no-reload-probe', 'kept')"
          )

          click_on "Edit"
          expect(page).to have_current_path(profile_path)

          fill_in "Display name", with: "Aldric the Bold"
          click_on "Save"

          expect(page).to have_text("Aldric the Bold")
          expect(page).to have_text("Display name saved.")
          expect(page).to have_current_path(profile_path)
          expect(page).to have_css("[data-no-reload-probe='kept']")
          expect(user.user_profile.reload.display_name).to eq("Aldric the Bold")
        end
      end
    end

    it "cancel reverts to the original name without saving" do
      user.user_profile.update!(display_name: "Original Name")
      visit profile_path

      click_on "Edit"
      fill_in "Display name", with: "Discarded Name"
      click_on "Cancel"

      expect(page).to have_text("Original Name")
      expect(page).not_to have_text("Discarded Name")
      expect(user.user_profile.reload.display_name).to eq("Original Name")
    end

    it "a validation failure keeps the field open with its error" do
      allow_any_instance_of(UserProfile).to receive(:save) do |record|
        record.errors.add(:display_name, "is too long")
        false
      end
      visit profile_path

      click_on "Edit"
      fill_in "Display name", with: "Some Name"
      click_on "Save"

      expect(page).to have_css("[data-inline-edit-field-target='edit']:not([hidden])", visible: :all)
      expect(page).to have_text("is too long")
    end
  end

  it "display name is shown in the nav drawer" do
    visit profile_path
    within("aside.nav-drawer", visible: :all) do
      expect(page).to have_text(user.display_name)
    end
  end

  it "the drawer profile chip links to the profile page" do
    visit root_path
    within("aside.nav-drawer", visible: :all) do
      expect(page).to have_css("a[href='#{profile_path}']", visible: :all)
    end
  end

  describe "hide OOC preference" do
    let(:game) { create(:game) }
    let(:scene) { create(:scene, game: game) }

    before do
      create(:game_member, :game_master, game: game, user: user)
      create(:scene_participant, scene: scene, user: user)
      create(:post, :ooc, scene: scene, user: user, content: "OOC: scheduling note")
      create(:post, scene: scene, user: user, content: "In character action.")
    end

    it "profile shows the hide-OOC default toggle" do
      visit profile_path
      expect(page).to have_text("Hide OOC by default")
      expect(page).to have_css("[role='switch']")
    end

    it "toggles the hide-OOC default from the profile" do
      visit profile_path

      toggle = find("[data-controller='ooc-filter'] [role='switch']")
      expect(toggle["aria-checked"]).to eq("false")

      page.execute_script(%q{document.querySelector('[data-controller="ooc-filter"] button').click()})

      expect(page).to have_css("[role='switch'][aria-checked='true']")
    end

    it "OOC posts are hidden on scene load when hide_ooc is enabled" do
      user.user_profile.update!(hide_ooc: true)

      visit game_scene_path(game, scene)

      expect(page).to have_text("In character action.")
      expect(page).not_to have_css('[data-testid="ooc-post"]', visible: true)
    end

    it "toggling Hide OOC in the scene header hides OOC posts" do
      visit game_scene_path(game, scene)
      find("button[aria-label='Toggle out-of-character posts']").click

      expect(page).not_to have_css('[data-testid="ooc-post"]', visible: true)
      expect(page).to have_text("In character action.")
    end
  end

  describe "AI display preference (AI Control Plane)" do
    it "profile shows the AI display control, tagged by default" do
      visit profile_path
      expect(page).to have_text("AI display")
      expect(page).to have_css("button[aria-pressed='true']", text: "Tagged")
    end

    it "switches the preference to shown in place, without a full page reload" do
      visit profile_path

      # Tag a body node OUTSIDE the swapped control. A full page render (the old
      # redirect, which Turbo Drive follows as a visit that rebuilds <body> from
      # fresh server HTML) drops this attribute; a targeted Turbo Stream swap of
      # just the control leaves it. Its survival is what proves the content no
      # longer jumps.
      page.execute_script(
        "document.querySelector('main, body').setAttribute('data-no-reload-probe', 'kept')"
      )

      click_on "Shown"

      expect(page).to have_text("AI display preference updated.")
      expect(page).to have_css("button[aria-pressed='true']", text: "Shown")
      expect(user.user_profile.reload.ai_display_preference).to eq("shown")
      expect(page).to have_css("[data-no-reload-probe='kept']")
    end

    it "switches the preference to hidden from the profile" do
      visit profile_path

      click_on "Hidden"

      expect(page).to have_text("AI display preference updated.")
      expect(user.user_profile.reload.ai_display_preference).to eq("hidden")
    end
  end

  describe "Your Games section" do
    let(:game) { create(:game) }

    before { create(:game_member, game: game, user: user) }

    it "shows one card per game with a create control per credential" do
      visit profile_path
      # SectionLabelComponent uppercases via CSS; assert the rendered form.
      expect(page).to have_text("YOUR GAMES")
      expect(page).to have_text(game.name)
      expect(page).to have_button("Create feed")
      expect(page).to have_button("Create token")
      expect(page).not_to have_text("RSS FEEDS")
      expect(page).not_to have_text("API TOKENS")
    end

    it "links to the API documentation from the section label" do
      visit profile_path

      expect(page).to have_link("View API documentation", href: "/api-docs")
    end

    it "creates a feed token and reveals the copyable URL" do
      visit profile_path
      click_on "Create feed"

      expect(page).to have_css(".secret-field")
      expect(page).to have_button("Revoke")
      # Masked by default; the real token is not in the visible input value.
      masked = find(".secret-field__input").value
      expect(masked).to match(/\A•+\z/)

      token = user.api_tokens.find_by(game: game, scope: "rss")
      click_on "Show"
      expect(find(".secret-field__input").value).to include("token=#{token.token}")
    end

    it "revokes an existing feed token" do
      create(:api_token, user: user, game: game, scope: "rss")
      visit profile_path

      expect(page).to have_button("Revoke")
      click_on "Revoke"

      expect(page).to have_button("Create feed")
      expect(user.api_tokens.where(scope: "rss")).to be_empty
    end

    it "creates an api token and reveals the raw value" do
      visit profile_path
      click_on "Create token"

      expect(page).to have_css(".secret-field")
      token = user.api_tokens.find_by(game: game, scope: "api")
      click_on "Show"
      expect(find(".secret-field__input").value).to eq(token.token)
    end

    it "shows the Fund AI toggle only when the viewer has a BYOK key" do
      visit profile_path
      expect(page).not_to have_text("Fund AI")

      create(:encrypted_value, :sealed, owner: user)
      visit profile_path
      expect(page).to have_text("Fund AI")
      expect(page).to have_text("Scene summaries")
    end

    it "funds a game's AI feature from its card and revokes it again" do
      create(:encrypted_value, :sealed, owner: user)
      visit profile_path

      find("button[aria-label='Fund Scene summaries with your key']").click
      expect(page).to have_css("button[aria-label='Stop funding Scene summaries with your key']")
      expect(GameKeyAuthorization.find_by(game: game, user: user, feature: "scene_summary")).to be_present

      find("button[aria-label='Stop funding Scene summaries with your key']").click
      expect(page).to have_css("button[aria-label='Fund Scene summaries with your key']")
      expect(GameKeyAuthorization.find_by(game: game, user: user, feature: "scene_summary")).to be_nil
    end
  end

  describe "profile show page" do
    it "shows display name and email" do
      visit profile_path

      expect(page).to have_text(user.display_name)
      expect(page).to have_text(user.email)
    end

    it "does not have its own games section (games live in the nav drawer)" do
      visit profile_path

      # The old profile had a "My Games" section; the redesign removed it.
      expect(page).not_to have_css(".app-body", text: "My Games")
    end
  end
end
