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

    it "submits feedback capturing the submitter and the page URL" do
      visit game_path(game)

      click_button "Send Feedback"
      expect(page).to have_css("[data-testid='feedback-modal']", visible: true)

      fill_in "feedback[body]", with: "The roster tab is slow to load."
      within "[data-testid='feedback-modal']" do
        click_button "Submit"
      end

      expect(page).to have_text("Thanks for your feedback!")

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
  end
end
