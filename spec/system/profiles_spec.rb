require "rails_helper"

RSpec.describe "Profiles", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before { sign_in_as(user) }

  it "user can update their display name" do
    click_on user.display_name

    fill_in "Display name", with: "Aldric the Bold"
    click_on "Save"

    expect(page).to have_text("Aldric the Bold")
  end

  it "display name is shown in the navbar" do
    expect(page).to have_text(user.display_name)
  end

  it "display name links to profile edit" do
    click_on user.display_name

    expect(page).to have_current_path(edit_profile_path)
  end
end
