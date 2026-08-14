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

  it "raises on an unknown theme, naming the offending theme" do
    expect { described_class.new(theme: :neon) }.to raise_error(ArgumentError, /Unknown theme: neon/)
  end

  # Turnstile tokens are single-use, so a form that submits without navigating has
  # to discard the spent one. The widget carries that behaviour itself rather than
  # each form reimplementing it.
  describe "token reset wiring" do
    it "wraps the widget in the turnstile Stimulus controller" do
      render_inline(described_class.new)
      expect(page).to have_css("div[data-controller='#{described_class::STIMULUS_CONTROLLER}']")
    end

    it "resets the widget when the surrounding form announces a completed submit" do
      render_inline(described_class.new)
      wrapper = page.find("div[data-controller='#{described_class::STIMULUS_CONTROLLER}']")
      expect(wrapper["data-action"]).to eq("turnstile:reset->#{described_class::STIMULUS_CONTROLLER}#reset")
    end

    # data-action means one thing to Stimulus and another to Turnstile; keeping the
    # controller on a wrapper is what stops the two from clobbering each other.
    it "leaves the widget's own data-action free for Turnstile's challenge label" do
      render_inline(described_class.new(action: "feedback"))
      expect(page).to have_css("div.cf-turnstile[data-action='feedback']")
      expect(page).to have_css("div[data-controller]:not(.cf-turnstile)")
    end
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
