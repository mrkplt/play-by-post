require "rails_helper"

# Regression for Fizzy #125: on a screen whose body is taller than the viewport,
# the frame's footer action button (e.g. "New Scene" on the scenes index) must
# stay pinned in view and remain clickable. It previously sank below the fold —
# the frame was `min-h-[96vh]` with a `sticky bottom-0` footer and no scroll
# containment, so the document scrolled and the button became unreachable / took
# repeated taps. The fix makes `.app-frame` a fixed-height flex column whose
# `.app-body` is the sole scroll region, so the footer is always visible.
#
# This is a MobileFrameComponent-convention invariant, exercised through the
# scenes index (a real footer-action screen) at both viewports.
RSpec.describe "Frame footer action reachability", type: :feature do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    # Enough scenes that the tree overflows even the 375x812 mobile viewport,
    # forcing the body to scroll — the condition under which the bug appeared.
    30.times { |i| create(:scene, game: game, title: "Scene number #{i + 1}") }
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "keeps the New Scene footer button clickable when the body overflows" do
        sign_in_as(gm)
        visit game_scenes_path(game)

        # The body scrolls, the frame itself does not — the document (html) must
        # not be the scroller, or the footer would ride below the fold. Assert on
        # computed style, since these are @apply'd utilities, not DOM classes.
        frame_overflow = page.evaluate_script(
          "getComputedStyle(document.querySelector('.app-frame')).overflowY"
        )
        body_overflow = page.evaluate_script(
          "getComputedStyle(document.querySelector('.app-body')).overflowY"
        )
        expect(frame_overflow).to eq("hidden")
        expect(body_overflow).to eq("auto")

        # The button must be actionable without the test scrolling the page to
        # find it: if the footer is truly pinned, this click navigates. If it had
        # sunk below the fold, Capybara/Playwright would fail to click it.
        click_on "New Scene"

        expect(page).to have_current_path(new_game_scene_path(game))
      end

      it "keeps the footer within the viewport's height" do
        sign_in_as(gm)
        visit game_scenes_path(game)

        footer_bottom = page.evaluate_script(
          "document.querySelector('.app-frame > footer').getBoundingClientRect().bottom"
        )
        viewport_height = page.evaluate_script("window.innerHeight")

        # The footer's bottom edge sits at (or within a hair of) the viewport
        # bottom — never scrolled off below it.
        expect(footer_bottom).to be <= (viewport_height + 1)
      end
    end
  end
end
