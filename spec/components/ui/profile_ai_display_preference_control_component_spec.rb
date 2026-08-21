require "rails_helper"

RSpec.describe Ui::ProfileAiDisplayPreferenceControlComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders a button for each option" do
    view = rendered(preference: "tagged", update_url: "/profile/update_ai_display_preference")
    expect(view).to have_button("Shown")
    expect(view).to have_button("Tagged")
    expect(view).to have_button("Hidden")
  end

  it "posts the option's value to the update endpoint" do
    view = rendered(preference: "tagged", update_url: "/profile/update_ai_display_preference")
    expect(view).to have_css("form[action='/profile/update_ai_display_preference'][method='post'] input[name='ai_display_preference'][value='shown']", visible: :all)
  end

  it "marks the current preference's button as pressed" do
    view = rendered(preference: "hidden", update_url: "/profile/update_ai_display_preference")
    expect(view).to have_css("button[aria-pressed='true']", text: "Hidden")
  end

  it "marks the non-current preferences' buttons as not pressed" do
    view = rendered(preference: "hidden", update_url: "/profile/update_ai_display_preference")
    expect(view).to have_css("button[aria-pressed='false']", text: "Shown")
    expect(view).to have_css("button[aria-pressed='false']", text: "Tagged")
  end

  describe "#active?" do
    it "returns true for the option matching the current preference" do
      component = described_class.new(preference: "shown", update_url: "/x")
      option = Ui::ProfileAiDisplayPreferenceControlComponent::Option.new(value: "shown", label: "Shown")
      expect(component.active?(option)).to be true
    end

    it "returns false for a non-matching option" do
      component = described_class.new(preference: "shown", update_url: "/x")
      option = Ui::ProfileAiDisplayPreferenceControlComponent::Option.new(value: "hidden", label: "Hidden")
      expect(component.active?(option)).to be false
    end
  end
end
