require "rails_helper"

RSpec.describe "Tablet GM dashboard", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    sign_in_as(gm)
    page.driver.resize_window_to(page.driver.current_window_handle, 768, 1024)
  end

  it "GM dashboard panels are reachable at 768px without horizontal scroll" do
    visit game_path(game)
    scroll_width = page.evaluate_script("document.body.scrollWidth")
    expect(scroll_width).to be <= 768
  end

  it "action buttons are non-overlapping at 768px" do
    visit game_path(game)
    result = page.evaluate_script(<<~JS)
      (function() {
        var btns = Array.from(document.querySelectorAll('button'));
        for (var i = 0; i < btns.length; i++) {
          for (var j = i + 1; j < btns.length; j++) {
            var a = btns[i].getBoundingClientRect();
            var b = btns[j].getBoundingClientRect();
            if (a.right > b.left && a.left < b.right && a.bottom > b.top && a.top < b.bottom) {
              return false;
            }
          }
        }
        return true;
      })()
    JS
    expect(result).to be true
  end

  it "sidebar is always visible at 768px (no hamburger animation)" do
    visit game_path(game)
    sidebar_transform = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('aside.sidebar')).transform"
    )
    # At 768px (md breakpoint), sidebar should be visible (not translated)
    expect(sidebar_transform).to eq("none")
  end

  it "no functionality is hidden based solely on screen size" do
    visit game_path(game)
    expect(page).to have_link("Manage Players")
    expect(page).to have_link("New Scene")
  end
end
