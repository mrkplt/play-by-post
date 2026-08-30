require "rails_helper"

RSpec.describe Ui::ProfileDisplayNameFieldComponent, type: :component do
  let(:profile_model) { build_stubbed(:user_profile, display_name: "Aragorn") }
  let(:profile) { UserProfilePresenter.new(profile_model) }

  def build_component(**opts)
    described_class.new(profile: profile, update_url: "/profile", **opts)
  end

  it "shows the current display name in view mode" do
    render_inline(build_component)
    expect(page).to have_text("Aragorn")
  end

  it "hides the edit form in view mode" do
    render_inline(build_component)
    expect(page).to have_css("[data-inline-edit-field-target='edit'][hidden]", visible: :all)
    expect(page).to have_css("[data-inline-edit-field-target='view']:not([hidden])", visible: :all)
  end

  it "renders an Edit control wired to the inline-edit-field controller" do
    render_inline(build_component)
    expect(page).to have_css("[data-action='inline-edit-field#edit']", text: "Edit")
  end

  it "pre-fills the edit field with the current display name" do
    render_inline(build_component)
    expect(page).to have_field("user_profile[display_name]", with: "Aragorn", visible: :all)
  end

  it "posts to the update url" do
    render_inline(build_component)
    expect(page).to have_css("form[action='/profile'][method='post'] input[name='_method'][value='patch']", visible: :all)
  end

  it "gives the control a stable id for Turbo Stream targeting" do
    render_inline(build_component)
    expect(page).to have_css("##{Ui::ProfileDisplayNameFieldComponent::CONTROL_ID}")
  end

  context "when editing: true" do
    it "shows the edit form and hides the view row" do
      render_inline(build_component(editing: true))
      expect(page).to have_css("[data-inline-edit-field-target='edit']:not([hidden])", visible: :all)
      expect(page).to have_css("[data-inline-edit-field-target='view'][hidden]", visible: :all)
    end
  end

  context "when the profile has a display_name error" do
    before { profile_model.errors.add(:display_name, "is too long") }

    it "reports editing? as true even when constructed with editing: false" do
      expect(build_component.editing?).to be(true)
    end

    it "renders the edit form open, with the error message" do
      render_inline(build_component)
      expect(page).to have_css("[data-inline-edit-field-target='edit']:not([hidden])", visible: :all)
      expect(page).to have_text("is too long")
    end
  end

  describe "#display_name_value" do
    it "returns the raw saved value, not the placeholder" do
      component = build_component
      expect(component.display_name_value).to eq("Aragorn")
    end

    it "returns a blank value as-is (not the placeholder text)" do
      profile_model.display_name = ""
      component = build_component
      expect(component.display_name_value).to eq("")
    end
  end
end
