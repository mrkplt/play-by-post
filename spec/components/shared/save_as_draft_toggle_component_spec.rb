require "rails_helper"

RSpec.describe Shared::SaveAsDraftToggleComponent, type: :component do
  it "renders the toggle wired to the draft controller with the explanatory label" do
    render_inline(described_class.new(checked: false))

    expect(page).to have_css("[data-draft-target='saveAsDraftToggle'][data-action='change->draft#toggleSaveAsDraft']")
    expect(page).to have_text("Save as draft")
  end

  it "starts checked when the record is already a draft" do
    render_inline(described_class.new(checked: true))
    expect(page).to have_css("input[type='checkbox'][checked]")
  end

  it "starts unchecked for a published record" do
    render_inline(described_class.new(checked: false))
    expect(page).to have_no_css("input[type='checkbox'][checked]")
  end

  context "in field mode (create form)" do
    it "renders a named checkbox plus its hidden off-value, not the autosave binding" do
      render_inline(described_class.new(checked: false, param: "page"))

      expect(page).to have_css("input[type='checkbox'][name='page[draft]'][value='1']")
      expect(page).to have_css("input[type='hidden'][name='page[draft]'][value='0']", visible: :all)
      expect(page).to have_no_css("[data-draft-target='saveAsDraftToggle']")
    end

    it "checks the box when the record is already a draft" do
      render_inline(described_class.new(checked: true, param: "page"))
      expect(page).to have_css("input[type='checkbox'][name='page[draft]'][checked]")
    end
  end
end
