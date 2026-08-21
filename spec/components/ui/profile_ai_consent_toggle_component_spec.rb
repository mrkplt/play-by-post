require "rails_helper"

RSpec.describe Ui::ProfileAiConsentToggleComponent, type: :component do
  def rendered(**opts)
    render_inline(described_class.new(**opts))
    page
  end

  it "renders the toggle in the off state" do
    expect(rendered(consented: false, toggle_url: "/profile/toggle_ai_summaries_consent"))
      .to have_css("[role='switch'][aria-checked='false']")
  end

  it "renders the toggle in the on state" do
    expect(rendered(consented: true, toggle_url: "/profile/toggle_ai_summaries_consent"))
      .to have_css("[role='switch'][aria-checked='true']")
  end

  it "posts to the toggle endpoint" do
    view = rendered(consented: false, toggle_url: "/profile/toggle_ai_summaries_consent")

    expect(view).to have_css("form[action='/profile/toggle_ai_summaries_consent'][method='post']")
  end

  it "uses the enable label when not consented" do
    view = rendered(consented: false, toggle_url: "/profile/toggle_ai_summaries_consent")
    expect(view).to have_css("button[aria-label='Enable AI features for your games']")
  end

  it "uses the disable label when consented" do
    view = rendered(consented: true, toggle_url: "/profile/toggle_ai_summaries_consent")
    expect(view).to have_css("button[aria-label='Disable AI features for your games']")
  end

  describe "#toggle_state" do
    it "returns :on when consented" do
      expect(described_class.new(consented: true, toggle_url: "/x").toggle_state).to eq(:on)
    end

    it "returns :off when not consented" do
      expect(described_class.new(consented: false, toggle_url: "/x").toggle_state).to eq(:off)
    end
  end
end
