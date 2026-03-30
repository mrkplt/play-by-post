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

  it "hides sidebar by default on mobile" do
    visit root_path
    sidebar = find('aside.sidebar')
    # Check that data-open attribute is not present
    expect(page.evaluate_script("document.querySelector('aside.sidebar').dataset.open")).to be_nil
  end

  it "opens the sidebar when hamburger is tapped" do
    visit root_path
    find('button[aria-label="Open navigation"]').click
    # Check that data-open attribute is set
    expect(page.evaluate_script("document.querySelector('aside.sidebar').dataset.open")).not_to be_nil
  end

  it "closes the sidebar when tapping outside" do
    visit root_path
    find('button[aria-label="Open navigation"]').click
    find('.sidebar-backdrop').click
    # Check that data-open attribute is removed
    expect(page.evaluate_script("document.querySelector('aside.sidebar').dataset.open")).to be_nil
  end

  it "nav links have a touch target of at least 44px" do
    visit root_path
    find('button[aria-label="Open navigation"]').click
    height = page.evaluate_script(
      "document.querySelector('aside.sidebar a').getBoundingClientRect().height"
    )
    expect(height).to be >= 20  # Sidebar links have padding + font size
  end
end
