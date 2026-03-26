require "rails_helper"

RSpec.describe "Mobile navigation", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before do
    sign_in_as(user)
    page.driver.resize_window_to(page.driver.current_window_handle, 375, 812)
  end

  it "hides hamburger when menu is empty" do
    visit destroy_user_session_path
    visit root_path
    expect(page).not_to have_css(".navbar__hamburger", visible: true)
  end

  it "shows the hamburger icon on mobile" do
    visit root_path
    expect(page).to have_css(".navbar__hamburger", visible: true)
  end

  it "hides nav menu by default on mobile" do
    visit root_path
    expect(page).to have_css(".navbar__menu[hidden]", visible: :all)
  end

  it "opens the nav menu when hamburger is tapped" do
    visit root_path
    find(".navbar__hamburger").click
    expect(page).not_to have_css(".navbar__menu[hidden]", visible: :all)
    expect(find(".navbar__menu")).to be_visible
  end

  it "clicking a nav link navigates away and collapses the menu" do
    visit root_path
    find(".navbar__hamburger").click
    find(".navbar__menu").click_link("Sign out")
    expect(page).not_to have_css(".navbar__hamburger", visible: true)
  end

  it "closes the nav menu when tapping outside" do
    visit root_path
    find(".navbar__hamburger").click
    find("main").click
    expect(page).to have_css(".navbar__menu[hidden]", visible: :all)
  end

  it "nav links have a touch target of at least 44px" do
    visit root_path
    find(".navbar__hamburger").click
    height = page.evaluate_script(
      "document.querySelector('.navbar__menu a').getBoundingClientRect().height"
    )
    expect(height).to be >= 44
  end
end
