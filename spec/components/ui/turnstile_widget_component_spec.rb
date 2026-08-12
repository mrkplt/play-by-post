require "rails_helper"

RSpec.describe Ui::TurnstileWidgetComponent, type: :component do
  # Turnstile is disabled in the test env by default; force it on to exercise
  # the rendering paths.
  before { allow(Turnstile).to receive(:enabled?).and_return(true) }

  it "renders the cf-turnstile container with the configured site key" do
    render_inline(described_class.new)
    expect(page).to have_css("div.cf-turnstile[data-sitekey='#{Turnstile.site_key}']")
  end

  it "loads the Cloudflare Turnstile script" do
    render_inline(described_class.new)
    expect(page).to have_css("script[src='#{Turnstile::SCRIPT_URL}'][async][defer]", visible: :all)
  end

  it "defaults the theme to auto" do
    render_inline(described_class.new)
    expect(page).to have_css("div.cf-turnstile[data-theme='auto']")
  end

  it "applies the given theme" do
    render_inline(described_class.new(theme: :dark))
    expect(page).to have_css("div.cf-turnstile[data-theme='dark']")
  end

  it "sets the action data attribute when given" do
    render_inline(described_class.new(action: "sign_in"))
    expect(page).to have_css("div.cf-turnstile[data-action='sign_in']")
  end

  it "omits the action attribute when not given" do
    render_inline(described_class.new)
    expect(page).not_to have_css("div.cf-turnstile[data-action]")
  end

  it "raises on an unknown theme" do
    expect { described_class.new(theme: :neon) }.to raise_error(ArgumentError, /Unknown theme/)
  end

  describe "all themes render without error" do
    Ui::TurnstileWidgetComponent::THEMES.each do |theme|
      it theme.to_s do
        expect { render_inline(described_class.new(theme: theme)) }.not_to raise_error
      end
    end
  end

  context "when Turnstile is disabled" do
    before { allow(Turnstile).to receive(:enabled?).and_return(false) }

    it "renders nothing" do
      render_inline(described_class.new)
      expect(page).not_to have_css("div.cf-turnstile")
      expect(page).not_to have_css("script", visible: :all)
    end
  end
end
