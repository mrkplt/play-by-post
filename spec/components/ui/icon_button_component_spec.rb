require "rails_helper"

RSpec.describe Ui::IconButtonComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders a button when no href given" do
    expect(rendered(label: "Menu") { "≡" }).to have_css("button[type='button']", text: "≡")
  end

  it "renders a link when href given" do
    expect(rendered(href: "/games", label: "Back") { "←" }).to have_css("a[href='/games']", text: "←")
  end

  it "applies the 44px-tall tap-target sizing" do
    expect(rendered(label: "Menu") { "≡" }).to have_css("button.h-11.w-8")
  end

  it "aligns to the start by default" do
    expect(rendered(label: "Menu") { "≡" }).to have_css("button.justify-start")
  end

  it "aligns centered when requested" do
    expect(rendered(align: :center, label: "Gear") { "⚙" }).to have_css("button.justify-center")
  end

  it "sets the aria-label" do
    expect(rendered(label: "Open navigation") { "≡" }).to have_css("button[aria-label='Open navigation']")
  end

  it "merges extra html_options onto the button" do
    expect(rendered(label: "Menu", html_options: { data: { action: "click->x#y" } }) { "≡" })
      .to have_css("button[data-action='click->x#y']")
  end

  it "merges extra html_options onto the link" do
    expect(rendered(href: "/g", label: "Gear", html_options: { data: { turbo: false } }) { "⚙" })
      .to have_css("a[data-turbo='false']")
  end

  it "builds link_options with class and aria-label keys" do
    c = described_class.new(href: "/g", label: "Back")
    expect(c.link_options).to eq(class: c.classes, "aria-label": "Back")
  end

  it "builds button_options with type, class and aria-label" do
    c = described_class.new(label: "Menu")
    expect(c.button_options).to eq(type: "button", class: c.classes, "aria-label": "Menu")
  end

  it "html_options override merged defaults on link" do
    c = described_class.new(href: "/g", label: "Back", html_options: { class: "override" })
    expect(c.link_options[:class]).to eq("override")
  end

  it "composes classes as BASE + alignment" do
    c = described_class.new(label: "x", align: :center)
    expect(c.classes).to eq("#{Ui::IconButtonComponent::BASE} #{Ui::IconButtonComponent::ALIGN.fetch(:center)}")
  end

  it "defaults label to an empty aria-label when omitted" do
    expect(described_class.new.button_options[:"aria-label"]).to eq("")
  end
end
