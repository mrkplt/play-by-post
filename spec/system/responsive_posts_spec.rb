require "rails_helper"

# Post readability invariants that must hold at every viewport, verified on both
# a phone and a desktop browser. (Was mobile_posts_spec, mobile-only.)
RSpec.describe "Post readability (responsive)", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:post, scene: scene, user: gm, content: "Hello world this is a story post.")
    sign_in_as(gm)
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "has no horizontal scroll" do
        visit game_scene_path(game, scene)
        scroll_width = page.evaluate_script("document.body.scrollWidth")
        expect(scroll_width).to be <= width
      end

      it "renders post body text at >= 16px" do
        visit game_scene_path(game, scene)
        font_size = page.evaluate_script(
          "parseFloat(window.getComputedStyle(document.querySelector('[data-testid=\"post-content\"]')).fontSize)"
        )
        expect(font_size).to be >= 16
      end

      it "keeps post images within their container" do
        create(:post, scene: scene, user: gm, content: '<img src="https://via.placeholder.com/800x400">')
        visit game_scene_path(game, scene)
        result = page.evaluate_script(<<~JS)
          (function() {
            var imgs = document.querySelectorAll('[data-testid="post-content"] img');
            for (var i = 0; i < imgs.length; i++) {
              if (imgs[i].offsetWidth > imgs[i].parentElement.offsetWidth) return false;
            }
            return true;
          })()
        JS
        expect(result).to be true
      end

      it "does not overflow horizontally from reply indentation" do
        create(:post, scene: scene, user: gm, content: "A reply post", is_ooc: false)
        visit game_scene_path(game, scene)
        overflow = page.evaluate_script(<<~JS)
          (function() {
            var replies = document.querySelectorAll('[data-testid="reply-post"]');
            for (var i = 0; i < replies.length; i++) {
              if (replies[i].scrollWidth > #{width}) return true;
            }
            return false;
          })()
        JS
        expect(overflow).to be false
      end
    end
  end
end
