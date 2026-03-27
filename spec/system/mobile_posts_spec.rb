require "rails_helper"

RSpec.describe "Mobile post readability", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:post, scene: scene, user: gm, content: "Hello world this is a story post.")
    sign_in_as(gm)
    page.driver.resize_window_to(page.driver.current_window_handle, 375, 812)
  end

  it "has no horizontal scroll at 375px viewport" do
    visit game_scene_path(game, scene)
    scroll_width = page.evaluate_script("document.body.scrollWidth")
    expect(scroll_width).to be <= 375
  end

  it "body text font-size is at least 16px on post content" do
    visit game_scene_path(game, scene)
    font_size = page.evaluate_script(
      "parseFloat(window.getComputedStyle(document.querySelector('.post__content')).fontSize)"
    )
    expect(font_size).to be >= 16
  end

  it "images in posts do not overflow their container" do
    create(:post, scene: scene, user: gm, content: '<img src="https://via.placeholder.com/800x400">')
    visit game_scene_path(game, scene)
    result = page.evaluate_script(<<~JS)
      (function() {
        var imgs = document.querySelectorAll('.post__content img');
        for (var i = 0; i < imgs.length; i++) {
          if (imgs[i].offsetWidth > imgs[i].parentElement.offsetWidth) return false;
        }
        return true;
      })()
    JS
    expect(result).to be true
  end

  it "reply indentation does not cause horizontal overflow" do
    create(:post, scene: scene, user: gm, content: "A reply post", is_ooc: false)
    visit game_scene_path(game, scene)
    overflow = page.evaluate_script(<<~JS)
      (function() {
        var replies = document.querySelectorAll('.post--reply');
        for (var i = 0; i < replies.length; i++) {
          if (replies[i].scrollWidth > 375) return true;
        }
        return false;
      })()
    JS
    expect(overflow).to be false
  end
end
