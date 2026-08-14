require "rails_helper"

# The "Send Feedback" control lives in the nav drawer and opens a modal that
# collects a free-form message, capturing who submitted it and the URL they
# were on. See REQUIREMENTS "Feedback".
RSpec.describe "Feedback", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game, name: "Sunken Archive") }

  before do
    create(:game_member, :game_master, user: user, game: game)
    sign_in_as(user)
  end

  context "on desktop (drawer docked)" do
    before { resize_window_to_viewport(1280, 900) }

    it "submits feedback in place, capturing the submitter and page URL without navigating" do
      visit game_path(game)

      click_button "Send Feedback"
      expect(page).to have_css("[data-testid='feedback-modal']", visible: true)

      fill_in "feedback[body]", with: "The roster tab is slow to load."
      within "[data-testid='feedback-modal']" do
        click_button "Submit"
      end

      # The modal swaps to its in-place confirmation — the page never navigates.
      expect(page).to have_text("Thanks for your feedback!")
      expect(page).to have_current_path(game_path(game))

      feedback = Feedback.last
      expect(feedback.user).to eq(user)
      expect(feedback.body).to eq("The roster tab is slow to load.")
      expect(feedback.url).to include(game_path(game))
    end

    it "dismisses the modal on Cancel without submitting" do
      visit root_path

      click_button "Send Feedback"
      expect(page).to have_css("[data-testid='feedback-modal']", visible: true)

      within "[data-testid='feedback-modal']" do
        click_button "Cancel"
      end

      expect(page).to have_no_css("[data-testid='feedback-modal']", visible: true)
      expect(Feedback.count).to eq(0)
    end

    it "keeps the modal within the viewport when feedback text is long, so it stays submittable" do
      visit root_path

      click_button "Send Feedback"
      expect(page).to have_css("[data-testid='feedback-modal']", visible: true)

      fill_in "feedback[body]", with: ("This is a very long piece of feedback. " * 400)

      modal_height = page.evaluate_script(
        "document.querySelector('[data-testid=\"feedback-modal\"]').getBoundingClientRect().height"
      )
      viewport_height = page.evaluate_script("window.innerHeight")

      expect(modal_height).to be <= viewport_height
    end
  end

  context "on mobile (drawer overlay)" do
    before { resize_window_to_viewport(375, 812) }

    it "opens the modal from the drawer at the full viewport width" do
      visit root_path
      find('button[aria-label="Open navigation"]').click
      click_button "Send Feedback"

      expect(page).to have_css("[data-testid='feedback-modal']", visible: true)

      # The modal is a sibling of the transformed drawer, so its fixed overlay
      # spans the viewport rather than being clamped to the 270px drawer box.
      width = page.evaluate_script(
        "document.querySelector('[data-testid=\"feedback-modal\"]').getBoundingClientRect().width"
      )
      expect(width).to be >= 375
    end

    it "keeps the submit button on screen so feedback can be submitted" do
      visit root_path
      find('button[aria-label="Open navigation"]').click
      click_button "Send Feedback"

      submit_bottom = page.evaluate_script(
        "document.querySelector('[data-testid=\"feedback-modal\"] input[type=\"submit\"]').getBoundingClientRect().bottom"
      )
      viewport_height = page.evaluate_script("window.innerHeight")

      expect(submit_bottom).to be <= viewport_height
    end
  end

  # Turnstile tokens are single-use and the modal never navigates, so before the
  # widget was taught to reset itself the second submit replayed the spent token
  # from the first and was rejected. Turnstile is off in the test env by default;
  # forcing it on is what puts the real widget (and its token) in the page.
  context "with Turnstile enabled" do
    # Every token siteverify was asked about, in order — lets an example assert on
    # what actually reached the server rather than on client-side bookkeeping.
    let(:verified_tokens) { [] }

    before do
      allow(Turnstile).to receive(:enabled?).and_return(true)
      # Stands in for siteverify, enforcing the two rules that matter here: a blank
      # token is refused, and a token is accepted once and rejected on replay.
      spent = []
      allow(TurnstileVerifier).to receive(:verify) do |token:, **|
        value = token.to_s
        verified_tokens << value
        next false if value.blank? || spent.include?(value)

        spent << value
        true
      end
      resize_window_to_viewport(1280, 900)
    end

    it "accepts a second submission, refreshing the spent token in between" do
      visit root_path

      # The real Cloudflare script owns the response input, so wait for it before
      # overriding reset() — writing into the input the script actually created.
      expect(page).to have_css("input[name='cf-turnstile-response']", visible: :all)

      # Models reset() as Turnstile actually implements it: the response is cleared
      # synchronously and the replacement token arrives later (there, over
      # postMessage from a freshly swapped iframe; here, on a timer). A stub that
      # repopulated the token synchronously would hide exactly the race this
      # example exists to pin — submitting before the new token lands.
      page.execute_script(<<~JS)
        window.__turnstileResets = 0;
        window.turnstile = {
          reset: function (element) {
            window.__turnstileResets += 1;
            var n = window.__turnstileResets;
            var input = (element || document).querySelector("input[name='cf-turnstile-response']");
            if (!input) { return; }
            input.value = "";
            setTimeout(function () { input.value = "token-" + n; }, 400);
          }
        };
        document.querySelector("input[name='cf-turnstile-response']").value = "token-0";
      JS

      click_button "Send Feedback"
      fill_in "feedback[body]", with: "First report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }
      expect(page).to have_text("Thanks for your feedback!")

      within("[data-testid='feedback-modal']") { click_button "Close" }
      click_button "Send Feedback"
      fill_in "feedback[body]", with: "Second report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }

      expect(page).to have_text("Thanks for your feedback!")
      expect(Feedback.count).to eq(2)
      expect(page.evaluate_script("window.__turnstileResets")).to be >= 1
    end

    # The submit path waits for the replacement token rather than posting the empty
    # value reset leaves behind, so the token reaching the server is always a live
    # one. Asserted on what siteverify received, since that is what the fix is for.
    it "waits for the refreshed token instead of submitting the empty one" do
      visit root_path
      expect(page).to have_css("input[name='cf-turnstile-response']", visible: :all)

      page.execute_script(<<~JS)
        window.turnstile = {
          reset: function (element) {
            var input = (element || document).querySelector("input[name='cf-turnstile-response']");
            if (!input) { return; }
            input.value = "";
            setTimeout(function () { input.value = "token-refreshed"; }, 600);
          }
        };
        document.querySelector("input[name='cf-turnstile-response']").value = "token-initial";
      JS

      click_button "Send Feedback"
      fill_in "feedback[body]", with: "First report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }
      expect(page).to have_text("Thanks for your feedback!")

      within("[data-testid='feedback-modal']") { click_button "Close" }
      click_button "Send Feedback"
      fill_in "feedback[body]", with: "Second report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }
      expect(page).to have_text("Thanks for your feedback!")

      expect(verified_tokens).to eq([ "token-initial", "token-refreshed" ])
    end

    # If reset fails to take — the CDN script blocked, the widget never
    # registered — the spent token is still sitting in the input. Waiting merely
    # for a token to be *present* would accept it and replay it, which is the bug
    # this all exists to prevent; the wait is for a token that actually changed.
    it "does not replay the spent token when the widget fails to refresh" do
      visit root_path
      expect(page).to have_css("input[name='cf-turnstile-response']", visible: :all)

      # Model a widget that never refreshes: remove the real Cloudflare iframe so
      # it cannot issue further tokens, leave a spent one in the input, and make
      # reset a no-op. The give-up window is shortened so the example does not sit
      # out the real one.
      page.execute_script(<<~JS)
        window.turnstile = { reset: function () {} };
        var wrapper = document.querySelector('[data-controller~="turnstile"]');
        wrapper.setAttribute("data-turnstile-timeout-value", "1000");
        wrapper.querySelectorAll("iframe").forEach(function (frame) { frame.remove(); });
        document.querySelector("input[name='cf-turnstile-response']").value = "token-stuck";
      JS

      click_button "Send Feedback"
      fill_in "feedback[body]", with: "First report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }
      expect(page).to have_text("Thanks for your feedback!")

      within("[data-testid='feedback-modal']") { click_button "Close" }
      click_button "Send Feedback"
      fill_in "feedback[body]", with: "Second report."
      within("[data-testid='feedback-modal']") { click_button "Submit" }

      # The second submit gives up waiting and discards the spent token rather
      # than replaying it, so siteverify is asked about a blank one and refuses.
      expect(page).to have_text("Something went wrong")
      expect(verified_tokens).to eq([ "token-stuck", "" ])
      expect(Feedback.count).to eq(1)
    end
  end
end
