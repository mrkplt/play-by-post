require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  def rendered(style: Ui::ButtonComponent::Style.new, link: Ui::ButtonComponent::Link.new, **opts, &block)
    render_inline(described_class.new(style: style, link: link, **opts), &block)
    page
  end

  def style(**opts)
    Ui::ButtonComponent::Style.new(**opts)
  end

  def link(**opts)
    Ui::ButtonComponent::Link.new(**opts)
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
    button = rendered(style: style(variant: :text), html_options: { class: "mt-2" }) { "X" }.find("button")
    expect(button[:class]).to include("mt-2", "cursor-pointer", "bg-transparent")
  end

  it "styles a text_danger button with the danger colour it owns" do
    button = rendered(style: style(variant: :text_danger)) { "Ban" }.find("button")
    expect(button[:class]).to include("text-danger", "cursor-pointer", "bg-transparent")
  end

  it "styles a text_muted button with the muted colour it owns" do
    button = rendered(style: style(variant: :text_muted)) { "Remove" }.find("button")
    expect(button[:class]).to include("text-row-ink", "cursor-pointer", "bg-transparent")
  end

  describe "all variants render without error" do
    Ui::ButtonComponent::VARIANTS.each_key do |variant|
      it variant.to_s do
        expect { render_inline(described_class.new(style: style(variant: variant))) }.not_to raise_error
      end
    end
  end

  describe "all sizes render without error" do
    Ui::ButtonComponent::SIZES.each_key do |size|
      it size.to_s do
        expect { render_inline(described_class.new(style: style(size: size))) }.not_to raise_error
      end
    end
  end

  context "when disabled" do
    it "applies disabled classes" do
      expect(rendered(style: style(state: :disabled)) { "Disabled" }).to have_css("button.opacity-50")
    end

    it "includes the disabled attribute" do
      expect(rendered(style: style(state: :disabled)) { "Disabled" }).to have_css("button[disabled]")
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
      expect(rendered(link: link(url: "/games/1")) { "Go" }).to have_css("a[href='/games/1']", text: "Go")
      expect(rendered(link: link(url: "/games/1")) { "Go" }).not_to have_css("button")
    end

    it "does not set a turbo-method attribute when method: is omitted" do
      expect(rendered(link: link(url: "/games/1")) { "Go" }).not_to have_css("a[data-turbo-method]")
    end

    it "sets data-turbo-method when method: is given" do
      expect(rendered(link: link(url: "/games/1/game_members/2", method: :delete)) { "Remove" })
        .to have_css("a[data-turbo-method='delete']")
    end

    it "sets data-turbo-confirm when confirm: is given" do
      expect(rendered(link: link(url: "/games/1", method: :patch, confirm: "Ban this player?")) { "Ban" })
        .to have_css("a[data-turbo-confirm='Ban this player?']")
    end

    it "does not set a turbo-confirm attribute when confirm: is omitted" do
      expect(rendered(link: link(url: "/games/1", method: :patch)) { "Reinstate" })
        .not_to have_css("a[data-turbo-confirm]")
    end

    it "merges caller-supplied data: alongside turbo attributes" do
      expect(rendered(link: link(url: "/games/1", data: { test_id: "ban-btn" })) { "Ban" })
        .to have_css("a[data-test-id='ban-btn']")
    end

    it "disables pointer events and dims when disabled" do
      expect(rendered(style: style(state: :disabled), link: link(url: "/games/1")) { "Go" }).to have_css("a.opacity-50")
    end

    it "appends an html_options class rather than replacing the variant/size classes" do
      result = rendered(link: link(url: "/games/1"), style: style(variant: :text), html_options: { class: "mt-2" }) { "X" }
      link_el = result.find("a")
      expect(link_el[:class]).to include("mt-2", "cursor-pointer", "bg-transparent")
    end
  end
end
