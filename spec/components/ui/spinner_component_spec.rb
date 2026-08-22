require "rails_helper"

RSpec.describe Ui::SpinnerComponent, type: :component do
  it "renders a status role with the animated ring base" do
    render_inline(described_class.new)

    expect(page).to have_css("span[role=status].animate-spin.rounded-full")
  end

  describe "sizes" do
    described_class::SIZES.each do |size, classes|
      it "renders the #{size} size, emitting each of its dimension classes" do
        render_inline(described_class.new(size: size))

        rendered = page.native.to_html
        classes.split.each { |klass| expect(rendered).to include(klass) }
      end
    end
  end

  it "raises on an off-scale size" do
    expect { render_inline(described_class.new(size: :huge)) }.to raise_error(KeyError)
  end

  it "carries a visually-hidden label for assistive tech" do
    render_inline(described_class.new(label: "Generating"))

    expect(page).to have_css("span.sr-only", text: "Generating")
  end

  it "defaults the label to Loading" do
    render_inline(described_class.new)

    expect(page).to have_css("span.sr-only", text: "Loading")
  end
end
