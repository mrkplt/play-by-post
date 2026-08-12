require "rails_helper"

RSpec.describe Ui::BadgeComponent, type: :component do
  def rendered(variant: :gray, &block)
    render_inline(described_class.new(variant: variant), &block)
    page
  end

  it "renders gray variant by default" do
    expect(rendered { "Former" }).to have_css("span.bg-slate-100.text-slate-600", text: "Former")
  end

  it "defaults the variant to :gray" do
    expect(described_class.new.classes).to eq("#{Ui::BadgeComponent::BASE} #{Ui::BadgeComponent::VARIANTS.fetch(:gray)}")
  end

  it "composes classes as BASE + variant" do
    expect(described_class.new(variant: :green).classes)
      .to eq("#{Ui::BadgeComponent::BASE} #{Ui::BadgeComponent::VARIANTS.fetch(:green)}")
  end

  it "renders the content block" do
    expect(rendered { "Active" }).to have_css("span", text: "Active")
  end

  it "exposes data-variant attribute" do
    expect(rendered(variant: :yellow) { "Private" }).to have_css("span[data-variant=yellow]")
  end

  describe "all variants render without error" do
    Ui::BadgeComponent::VARIANTS.each_key do |variant|
      it variant.to_s do
        expect { render_inline(described_class.new(variant: variant)) }.not_to raise_error
      end
    end
  end

  describe "variant classes" do
    it "yellow applies yellow background and text" do
      expect(rendered(variant: :yellow) { "Private" }).to have_css("span.bg-yellow-100.text-yellow-800")
    end

    it "gray applies slate background and text" do
      expect(rendered(variant: :gray) { "Resolved" }).to have_css("span.bg-slate-100.text-slate-600")
    end

    it "green applies green background and text" do
      expect(rendered(variant: :green) { "Active" }).to have_css("span.bg-green-100.text-green-800")
    end

    it "blue applies blue background and text" do
      expect(rendered(variant: :blue) { "GM" }).to have_css("span.bg-blue-100.text-blue-800")
    end

    it "slate applies the dark-surface slate tint" do
      expect(rendered(variant: :slate) { "Removed" }).to have_css("span.uppercase.tracking-\\[0\\.03em\\]", text: "Removed")
    end

    it "danger applies the dark-surface danger tint" do
      expect(rendered(variant: :danger) { "Banned" }).to have_css("span.text-badge-danger-text", text: "Banned")
    end

    it "goldish applies the dark-surface gold tint" do
      expect(rendered(variant: :goldish) { "GM" }).to have_css("span.text-badge-gold-text", text: "GM")
    end
  end
end
