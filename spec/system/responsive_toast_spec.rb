require "rails_helper"

# Toast behaviour that must hold at every viewport.
#
# These specs exist because of a real regression: the flash used to render in
# document flow above `yield`, which put it above each screen's dark header
# and pushed the whole app frame down 64px. The message was in the DOM and
# technically visible, but the shift plus the off-header position meant a
# notice after a Turbo form submit read to the user as "nothing happened".
# The no-reflow assertion below is the one that would have caught it.
RSpec.describe "Toasts (responsive)", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let!(:member) { create(:game_member, :game_master, game: game, user: gm) }
  # Built through the factory (not game.notebook_entries.create!) so the
  # Versionable snapshot is attributed: an entry has no owning user, so it takes
  # attribution from Current.user, which the factory's to_create supplies.
  let!(:entry) { create(:notebook_entry, game: game, editor: gm, title: "Probe Entry", body: "body text") }

  before { sign_in_as(gm) }

  def frame_top
    page.evaluate_script("document.querySelector('.app-frame').getBoundingClientRect().top")
  end

  # The lane picker on the entry edit screen submits through Turbo and
  # redirects with a notice — the exact path the original bug was found on.
  def move_lane(to:)
    select to, from: "notebook_entry[status]"
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before do
        resize_window_to_viewport(width, height)
        visit edit_game_notebook_entry_path(game, entry)
      end

      it "shows the notice after a Turbo-driven redirect" do
        move_lane(to: "Expand")

        expect(page).to have_css("[data-testid='toast']", text: "Entry moved.")
      end

      it "does not move the page when a toast appears" do
        before_top = frame_top
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']")

        expect(frame_top).to eq(before_top)
      end

      it "renders the toast out of flow, above the content" do
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']")

        layer = page.evaluate_script(<<~JS)
          (() => {
            const el = document.querySelector('.toast-layer');
            const s = window.getComputedStyle(el);
            return { position: s.position, zIndex: parseInt(s.zIndex, 10) };
          })()
        JS

        expect(layer["position"]).to eq("fixed")
        expect(layer["zIndex"]).to be > 50 # above the nav drawer
      end

      it "keeps the toast inside the viewport" do
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']")

        rect = page.evaluate_script(
          "(() => { const r = document.querySelector('.toast').getBoundingClientRect();" \
          "return { left: r.left, right: r.right, top: r.top }; })()"
        )

        expect(rect["top"]).to be >= 0
        expect(rect["left"]).to be >= 0
        expect(rect["right"]).to be <= width
      end

      # Regression for the "off-centre of the whole page" report: the toast must
      # centre on the full viewport, not on the content pane right of the desktop
      # nav rail. Under the old `.nav-drawer ~ .toast-layer { left: 270px }` rule
      # the toast centre sat ~135px right of the page centre on desktop.
      it "centres the toast on the full page width" do
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']")

        centre = page.evaluate_script(
          "(() => { const r = document.querySelector('.toast').getBoundingClientRect();" \
          "return (r.left + r.right) / 2; })()"
        )

        expect(centre).to be_within(1).of(width / 2.0)
      end

      it "does not intercept clicks meant for the content beneath it" do
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']")

        events = page.evaluate_script(
          "window.getComputedStyle(document.querySelector('.toast-layer')).pointerEvents"
        )

        expect(events).to eq("none")
      end

      it "fades the success toast away on its own" do
        move_lane(to: "Expand")
        expect(page).to have_css("[data-testid='toast']", text: "Entry moved.")

        # 2s solid + 3s fade, plus slack for the browser.
        expect(page).to have_no_css("[data-testid='toast']", wait: 10)
      end

      it "leaves no gap behind once the toast has gone" do
        before_top = frame_top
        move_lane(to: "Expand")
        expect(page).to have_no_css("[data-testid='toast']", wait: 10)

        expect(frame_top).to eq(before_top)
      end
    end
  end
end
