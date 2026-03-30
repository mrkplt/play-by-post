require "rails_helper"

RSpec.describe "Profiles", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before { sign_in_as(user) }

  it "user can update their display name" do
    visit profile_path
    click_on "Edit Profile"

    fill_in "Display name", with: "Aldric the Bold"
    click_on "Save"

    expect(page).to have_text("Aldric the Bold")
  end

  it "display name is shown in the sidebar" do
    expect(page).to have_text(user.display_name)
  end

  it "sidebar user name links to profile show" do
    click_on user.display_name
    expect(page).to have_current_path(profile_path)
  end

  describe "profile show page" do
    it "shows display name and email" do
      visit profile_path

      expect(page).to have_text(user.display_name)
      expect(page).to have_text(user.email)
    end

    it "shows game list with role badges" do
      game = create(:game, name: "Test Campaign")
      create(:game_member, :game_master, game: game, user: user)

      visit profile_path

      expect(page).to have_text("Test Campaign")
      expect(page).to have_text("GM")
    end

    it "edit link navigates to edit page" do
      visit profile_path
      click_on "Edit Profile"

      expect(page).to have_current_path(edit_profile_path)
    end

    it "edit page has cancel link back to show" do
      visit edit_profile_path

      click_on "Cancel"
      expect(page).to have_current_path(profile_path)
    end
  end
end
