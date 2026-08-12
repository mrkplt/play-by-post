# typed: false

require "rails_helper"

RSpec.describe Ui::SecretFieldComponent, type: :component do
  subject(:component) do
    described_class.new(value: "https://example.com/feeds?token=secret", label: "Feed URL")
  end

  it "renders the value in a masked (password) input by default" do
    render_inline(component)
    input = page.find("input")
    expect(input[:type]).to eq("password")
    expect(input[:value]).to eq("https://example.com/feeds?token=secret")
  end

  it "labels the input for accessibility" do
    render_inline(component)
    expect(page).to have_css("input[aria-label='Feed URL']")
  end

  it "wires the secret-field controller with toggle and copy targets" do
    render_inline(component)
    expect(page).to have_css("[data-controller='secret-field']")
    expect(page).to have_css("[data-secret-field-target='input']")
    expect(page).to have_css("[data-action='secret-field#toggle']")
    expect(page).to have_css("[data-action='secret-field#copy']")
  end

  it "exposes value and label readers" do
    expect(component.value).to eq("https://example.com/feeds?token=secret")
    expect(component.label).to eq("Feed URL")
  end
end
