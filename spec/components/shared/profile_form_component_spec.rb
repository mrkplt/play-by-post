require "rails_helper"

RSpec.describe Shared::ProfileFormComponent, type: :component do
  let(:profile) { build_stubbed(:user_profile, display_name: "Aragorn") }

  def build_component(profile:)
    described_class.new(profile: profile)
  end

  it "renders a display_name field pre-filled with the current value" do
    render_inline(build_component(profile: profile))
    expect(page).to have_field("user_profile[display_name]", with: "Aragorn")
  end

  it "gives the form a stable id for the external submit button" do
    render_inline(build_component(profile: profile))
    expect(page).to have_css("form#profile_edit_form")
  end

  describe "error surfacing" do
    it "reports no error on a clean profile" do
      expect(build_component(profile: profile).errors?).to be(false)
    end

    it "surfaces a display_name validation message" do
      profile.errors.add(:display_name, "is too long")
      component = build_component(profile: profile)
      expect(component.errors?).to be(true)
      expect(component.error_message).to eq("is too long")
      render_inline(component)
      expect(page).to have_text("is too long")
    end
  end
end
