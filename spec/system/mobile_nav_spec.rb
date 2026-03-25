require "rails_helper"

RSpec.describe "Mobile navigation", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before do
    sign_in_as(user)
    page.driver.browser.new_context(viewport: { width: 375, height: 812 })
  end

  def mobile_viewport
    page.execute_script("window.innerWidth = 375")
    page.driver.resize(375, 812)
  end

  it "shows the hamburger icon on mobile" do
    mobile_viewport
    visit root_path
    expect(page).to have_css(".navbar__hamburger", visible: true)
  end

  it "hides nav menu by default on mobile" do
    mobile_viewport
    visit root_path
    expect(page).to have_css(".navbar__menu[hidden]")
  end

  it "opens the nav menu when hamburger is tapped" do
    mobile_viewport
    visit root_path
    find(".navbar__hamburger").click
    expect(page).not_to have_css(".navbar__menu[hidden]")
    expect(find(".navbar__menu")).to be_visible
  end

  it "closes the nav menu when a link is selected" do
    mobile_viewport
    visit root_path
    find(".navbar__hamburger").click
    find(".navbar__menu").click_link("Sign out")
    expect(page).to have_css(".navbar__menu[hidden]")
  end

  it "closes the nav menu when tapping outside" do
    mobile_viewport
    visit root_path
    find(".navbar__hamburger").click
    find("main").click
    expect(page).to have_css(".navbar__menu[hidden]")
  end

  it "nav links have a touch target of at least 44px" do
    mobile_viewport
    visit root_path
    find(".navbar__hamburger").click
    height = page.evaluate_script(
      "document.querySelector('.navbar__menu a').getBoundingClientRect().height"
    )
    expect(height).to be >= 44
  end
end
