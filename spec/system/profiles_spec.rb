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
