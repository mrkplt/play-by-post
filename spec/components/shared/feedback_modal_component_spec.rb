require "rails_helper"

RSpec.describe Shared::FeedbackModalComponent, type: :component do
  subject(:component) { described_class.new }

  describe "rendering" do
    # The modal starts hidden, so its contents are inspected with visible: :all.
    before { render_inline(component) }

    it "renders a modal wired to the feedback controller" do
      expect(page).to have_css("[data-testid='feedback-modal'][data-feedback-target='modal']", visible: :all)
    end

    it "posts to the feedback route and submits via the controller (no navigation)" do
      form = page.find("form[action='/feedback']", visible: :all)
      expect(form["data-action"]).to eq("submit->feedback#submit")
    end

    it "renders a textarea for the feedback body" do
      expect(page).to have_css("textarea[name='feedback[body]'][data-feedback-target='field']", visible: :all)
    end

    it "renders a hidden url field the controller fills on open" do
      expect(page).to have_css("input[type='hidden'][name='feedback[url]'][data-feedback-target='url']", visible: :all)
    end

    it "renders a submit and a cancel control" do
      expect(page).to have_css("input[type='submit'][value='Submit']", visible: :all)
      expect(page).to have_css("button[data-action='click->feedback#close']", text: "Cancel", visible: :all)
    end

    it "renders hidden success and error regions the controller reveals" do
      expect(page).to have_css("[data-feedback-target='successPanel'][hidden]", visible: :all)
      expect(page).to have_css("[data-feedback-target='error'][hidden]", visible: :all)
    end
  end
end
