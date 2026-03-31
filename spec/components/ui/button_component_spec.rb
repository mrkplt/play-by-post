require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders primary variant by default" do
    expect(rendered { "Label" }).to have_css("button.bg-blue-600", text: "Label")
  end

  it "renders the content block" do
    expect(rendered { "Click me" }).to have_css("button", text: "Click me")
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
end
