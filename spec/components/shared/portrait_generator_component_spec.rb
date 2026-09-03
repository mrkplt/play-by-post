require "rails_helper"

# The AI portrait generation control's three states.
RSpec.describe Shared::PortraitGeneratorComponent, type: :component do
  def render_state(pending:, failure_reason: nil)
    render_inline(described_class.new(
      generate_url: "/generate", poll_url: "/generate", pending: pending, failure_reason: failure_reason
    ))
  end

  it "renders inside the stable target id" do
    render_state(pending: false)
    expect(page).to have_css("##{described_class::TARGET_ID}")
  end

  context "pending" do
    it "shows the spinner wired to the portrait-poll controller, no form" do
      render_state(pending: true)

      expect(page).to have_css("[data-controller='portrait-poll'][data-portrait-poll-url-value='/generate']")
      expect(page).to have_text(described_class::PENDING_MESSAGE)
      expect(page).not_to have_css("form")
    end
  end

  context "idle" do
    it "shows the prompt form posting to the generate url, no spinner" do
      render_state(pending: false)

      expect(page).to have_css("form[action='/generate']")
      expect(page).not_to have_css("[data-controller='portrait-poll']")
    end
  end

  context "failed" do
    it "shows the failure reason and the form to retry" do
      render_state(pending: false, failure_reason: "That prompt was blocked.")

      expect(page).to have_text("That prompt was blocked.")
      expect(page).to have_css("form[action='/generate']")
    end
  end
end
