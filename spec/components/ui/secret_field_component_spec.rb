require "rails_helper"

RSpec.describe Ui::SecretFieldComponent, type: :component do
  let(:secret) { "https://example.com/rss/feed?token=abc123" }

  it "renders the label" do
    render_inline(described_class.new(value: secret, label: "Feed URL"))
    expect(page).to have_css("label.secret-field__label", text: "Feed URL")
  end

  it "masks the value in the visible input and does not render the real value there" do
    render_inline(described_class.new(value: secret, label: "Feed URL"))
    input = page.find("input.secret-field__input")
    expect(input.value).to eq("•" * 24)
    expect(input.value).not_to include("abc123")
  end

  it "carries the real value in the Stimulus value attribute for copy/reveal" do
    render_inline(described_class.new(value: secret, label: "Feed URL"))
    expect(page).to have_css(%(.secret-field[data-secret-field-value-value="#{secret}"]))
  end

  it "wires the reveal toggle and copy actions" do
    render_inline(described_class.new(value: secret, label: "Feed URL"))
    expect(page).to have_css('[data-action="secret-field#toggle"]')
    expect(page).to have_css('[data-action="secret-field#copy"]')
  end

  describe "#masked_value" do
    it "is a fixed-width dotted string that does not vary with value length" do
      short = described_class.new(value: "x", label: "L").masked_value
      long = described_class.new(value: "x" * 999, label: "L").masked_value
      expect(short).to eq(long)
      expect(short).to match(/\A•+\z/)
    end
  end
end
