require "rails_helper"

RSpec.describe "Mobile navigation", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before do
    sign_in_as(user)
    page.driver.resize_window_to(page.driver.current_window_handle, 375, 812)
  end

  it "shows the hamburger icon on mobile" do
    visit root_path
    expect(page).to have_css('button[aria-label="Open navigation"]', visible: true)
  end

  it "hides the nav drawer by default" do
    visit root_path
    expect(page.evaluate_script("document.querySelector('aside.nav-drawer').dataset.open")).to be_nil
  end

  it "opens the drawer when the hamburger is tapped" do
    visit root_path
    find('button[aria-label="Open navigation"]').click
    expect(page.evaluate_script("document.querySelector('aside.nav-drawer').dataset.open")).not_to be_nil
  end

  it "closes the drawer when tapping the backdrop" do
    visit root_path
    find('button[aria-label="Open navigation"]').click
    find('.nav-drawer-backdrop').click
    expect(page.evaluate_script("document.querySelector('aside.nav-drawer').dataset.open")).to be_nil
  end

  it "drawer game rows have a comfortable touch target" do
    create(:game_member, user: user, game: create(:game, name: "Adventure"))
    visit root_path
    find('button[aria-label="Open navigation"]').click
    height = page.evaluate_script(
      "document.querySelector('aside.nav-drawer nav a').getBoundingClientRect().height"
    )
    expect(height).to be >= 20
  end
end
