require "rails_helper"

RSpec.describe Shared::DraftRecoveryComponent, type: :component do
  let(:discard_path) { "/games/1/scenes/2/posts/discard_draft" }
  let(:notice) { "You have an unsaved draft from this scene." }

  def build_component(draft:)
    described_class.new(draft: draft, discard_path: discard_path, notice: notice)
  end

  it "renders nothing when there is no draft" do
    render_inline(build_component(draft: nil))
    expect(page).to have_no_text("unsaved draft")
  end

  it "reports draft? false when there is no draft" do
    expect(build_component(draft: nil).draft?).to be(false)
  end

  context "when a draft is present" do
    # Any presenter exposing #content — the component is record-agnostic.
    let(:draft) { instance_double(PostPresenter, content: "Half-written reply") }

    it "reports draft? true" do
      expect(build_component(draft: draft).draft?).to be(true)
    end

    it "shows the supplied notice" do
      render_inline(build_component(draft: draft))
      expect(page).to have_text("You have an unsaved draft from this scene.")
    end

    it "renders the draft content" do
      render_inline(build_component(draft: draft))
      expect(page).to have_text("Half-written reply")
    end

    it "renders a Discard Draft control pointing at the discard path" do
      render_inline(build_component(draft: draft))
      expect(page).to have_css(
        "a[href='/games/1/scenes/2/posts/discard_draft']",
        text: "Discard Draft"
      )
    end
  end
end
