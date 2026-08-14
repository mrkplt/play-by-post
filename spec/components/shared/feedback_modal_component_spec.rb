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

    it "wires the feedback body to the markdown toolbar" do
      expect(page).to have_css("[data-controller~='markdown-preview'][data-controller~='markdown-toolbar']", visible: :all)
      expect(page).to have_css("textarea.markdown-editor[data-markdown-preview-target='input']", visible: :all)
      expect(page).to have_css("[role='toolbar'][aria-label='Markdown formatting']", visible: :all)
    end

    it "omits the markdown live preview so the modal stays short enough to submit on mobile" do
      expect(page).to have_no_css("[data-markdown-preview-target='preview']", visible: :all)
    end

    it "caps the editor height inside a wide modal and keeps the card under the viewport" do
      card = page.find("[data-testid='feedback-modal'] .max-w-3xl", visible: :all)
      expect(card["class"]).to include("max-h-[86vh]")
      # The cap is a step on the editor's shared vh scale, so the textarea
      # stays proportional to the modal rather than a fixed 16rem.
      textarea = page.find("textarea.markdown-editor", visible: :all)
      expect(textarea["style"]).to eq("max-height: #{Ui::MarkdownEditorComponent::Config::HEIGHTS.fetch(:md)}")
      expect(page).to have_css("textarea.markdown-editor:not([class*='resize-y'])", visible: :all)
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

  # The modal finds the Turnstile widget by controller name to tell it a submit
  # finished, so the name is a contract between Ruby and JS. Nothing else fails
  # fast if they drift: the widget is absent in the test env, and the system spec
  # that would notice runs only in the heavy tier.
  it "looks the widget up by the name the component actually renders" do
    js = Rails.root.join("app/javascript/controllers/feedback_controller.js").read
    declared = js[/const TURNSTILE_CONTROLLER = "([^"]+)"/, 1]

    expect(declared).to eq(Ui::TurnstileWidgetComponent::STIMULUS_CONTROLLER)
  end
end
