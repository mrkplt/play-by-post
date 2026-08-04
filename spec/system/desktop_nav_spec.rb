require "rails_helper"

# Desktop counterpart to mobile_nav_spec. At >=1024px the nav drawer docks open
# as a permanent left rail: the hamburger and backdrop disappear, the drawer
# sits on-screen without a tap, and page content is offset to the right of the
# rail. (Below 1024px the mobile overlay drawer is covered by mobile_nav_spec
# and tablet_gm_dashboard_spec.)
RSpec.describe "Desktop navigation", type: :feature do
  let(:user) { create(:user, :with_profile) }

  before do
    sign_in_as(user)
    page.driver.resize_window_to(page.driver.current_window_handle, 1280, 900)
  end

  it "hides the hamburger on desktop" do
    visit root_path
    expect(page).to have_no_css('button[aria-label="Open navigation"]', visible: true)
  end

  it "docks the nav drawer on-screen without a tap" do
    visit root_path
    left = page.evaluate_script(
      "document.querySelector('aside.nav-drawer').getBoundingClientRect().left"
    )
    expect(left).to be_within(1).of(0)
  end

  it "hides the backdrop" do
    visit root_path
    expect(page).to have_no_css(".nav-drawer-backdrop", visible: true)
  end

  it "offsets the page content to the right of the rail" do
    visit root_path
    margin = page.evaluate_script(
      "getComputedStyle(document.querySelector('aside.nav-drawer + div')).marginLeft"
    )
    expect(margin).to eq("270px")
  end

  it "shows drawer games and account links without opening anything" do
    create(:game_member, user: user, game: create(:game, name: "Adventure"))
    visit root_path
    expect(page).to have_link("Adventure", visible: true)
    expect(page).to have_link("Account Settings", visible: true)
  end

  it "does not overflow horizontally past the rail" do
    create(:game_member, :game_master, user: user, game: create(:game, name: "Adventure"))
    visit root_path
    scroll_width = page.evaluate_script("document.body.scrollWidth")
    expect(scroll_width).to be <= 1280
  end
end
