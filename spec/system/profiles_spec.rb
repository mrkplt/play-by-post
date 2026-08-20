require "rails_helper"

RSpec.describe "Profiles", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before { sign_in_as(user) }

  it "user can update their display name" do
    visit profile_path
    click_on "Edit"

    fill_in "Display name", with: "Aldric the Bold"
    click_on "Save"

    expect(page).to have_text("Aldric the Bold")
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
      expect(page).to have_link("View Profile", href: profile_path, visible: :all)
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

  describe "AI summaries consent (AI Control Plane)" do
    it "profile shows the AI consent toggle, off by default" do
      visit profile_path
      expect(page).to have_text("AI features")
      expect(page).to have_css("[role='switch'][aria-checked='false']")
    end

    it "toggles AI consent on from the profile" do
      visit profile_path

      find("button[aria-label='Enable AI features for your games']").click

      expect(page).to have_text("AI scene summaries enabled for your games.")
      expect(user.user_profile.reload.ai_summaries_consent).to be(true)
    end

    it "toggles AI consent back off from the profile" do
      user.user_profile.update!(ai_summaries_consent: true)
      visit profile_path

      find("button[aria-label='Disable AI features for your games']").click

      expect(page).to have_text("AI scene summaries disabled for your games.")
      expect(user.user_profile.reload.ai_summaries_consent).to be(false)
    end
  end

  describe "RSS feeds section" do
    let(:game) { create(:game) }

    before { create(:game_member, game: game, user: user) }

    it "lists the user's game with a create-feed control" do
      visit profile_path
      # SectionLabelComponent uppercases via CSS; assert the rendered form.
      expect(page).to have_text("RSS FEEDS")
      expect(page).to have_text(game.name)
      expect(page).to have_button("Create feed")
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
  end

  describe "API tokens section" do
    let(:game) { create(:game) }

    before { create(:game_member, game: game, user: user) }

    it "links to the API documentation from the API tokens section" do
      visit profile_path

      expect(page).to have_text("API TOKENS")
      expect(page).to have_link("View API documentation", href: "/api-docs")
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

    it "edit link navigates to edit page" do
      visit profile_path
      click_on "Edit"

      expect(page).to have_current_path(edit_profile_path)
    end

    it "edit page has cancel link back to show" do
      visit edit_profile_path

      click_on "Cancel"
      expect(page).to have_current_path(profile_path)
    end
  end
end
