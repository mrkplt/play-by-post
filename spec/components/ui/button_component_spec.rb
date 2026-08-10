require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders primary variant by default" do
    expect(rendered { "Label" }).to have_css("button.bg-accent", text: "Label")
  end

  it "renders the content block" do
    expect(rendered { "Click me" }).to have_css("button", text: "Click me")
  end

  it "defaults the button type to button (not submit)" do
    expect(rendered { "Label" }).to have_css("button[type='button']")
  end

  it "honors an explicit submit type via html_options" do
    expect(rendered(html_options: { type: "submit" }) { "Label" }).to have_css("button[type='submit']")
  end

  it "appends an html_options class rather than replacing the variant/size classes" do
    button = rendered(variant: :text, html_options: { class: "text-danger" }) { "Ban" }.find("button")
    expect(button[:class]).to include("text-danger", "cursor-pointer", "bg-transparent")
  end

  describe "all variants render without error" do
    Ui::ButtonComponent::VARIANTS.each_key do |variant|
      it variant.to_s do
        expect { render_inline(described_class.new(variant: variant)) }.not_to raise_error
      end
    end
  end

  describe "all sizes render without error" do
    Ui::ButtonComponent::SIZES.each_key do |size|
      it size.to_s do
        expect { render_inline(described_class.new(size: size)) }.not_to raise_error
      end
    end
  end

  context "when disabled" do
    it "applies disabled classes" do
      expect(rendered(disabled: true) { "Disabled" }).to have_css("button.opacity-50")
    end

    it "includes the disabled attribute" do
      expect(rendered(disabled: true) { "Disabled" }).to have_css("button[disabled]")
    end
  end

  context "when not disabled" do
    it "does not apply disabled classes" do
      expect(rendered { "Active" }).not_to have_css("button.opacity-50")
    end

    it "does not include the disabled attribute" do
      expect(rendered { "Active" }).not_to have_css("button[disabled]")
    end
  end

  context "when url: is given" do
    it "renders a link instead of a button" do
      expect(rendered(url: "/games/1") { "Go" }).to have_css("a[href='/games/1']", text: "Go")
      expect(rendered(url: "/games/1") { "Go" }).not_to have_css("button")
    end

    it "does not set a turbo-method attribute when method: is omitted" do
      expect(rendered(url: "/games/1") { "Go" }).not_to have_css("a[data-turbo-method]")
    end

    it "sets data-turbo-method when method: is given" do
      expect(rendered(url: "/games/1/game_members/2", method: :delete) { "Remove" })
        .to have_css("a[data-turbo-method='delete']")
    end

    it "sets data-turbo-confirm when confirm: is given" do
      expect(rendered(url: "/games/1", method: :patch, confirm: "Ban this player?") { "Ban" })
        .to have_css("a[data-turbo-confirm='Ban this player?']")
    end

    it "does not set a turbo-confirm attribute when confirm: is omitted" do
      expect(rendered(url: "/games/1", method: :patch) { "Reinstate" })
        .not_to have_css("a[data-turbo-confirm]")
    end

    it "merges caller-supplied data: alongside turbo attributes" do
      expect(rendered(url: "/games/1", data: { test_id: "ban-btn" }) { "Ban" })
        .to have_css("a[data-test-id='ban-btn']")
    end

    it "disables pointer events and dims when disabled" do
      expect(rendered(url: "/games/1", disabled: true) { "Go" }).to have_css("a.opacity-50")
    end

    it "appends an html_options class rather than replacing the variant/size classes" do
      link = rendered(url: "/games/1", variant: :text, html_options: { class: "text-danger" }) { "Ban" }.find("a")
      expect(link[:class]).to include("text-danger", "cursor-pointer", "bg-transparent")
    end
  end
end
