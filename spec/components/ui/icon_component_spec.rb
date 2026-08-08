require "rails_helper"

RSpec.describe Ui::IconComponent, type: :component do
  describe "ICON_MAP" do
    it "maps :crown to crown-03" do
      expect(described_class::ICON_MAP[:crown]).to eq("crown-03")
    end

    it "maps :settings to settings-01" do
      expect(described_class::ICON_MAP[:settings]).to eq("settings-01")
    end

    it "maps :cancel to cancel-01" do
      expect(described_class::ICON_MAP[:cancel]).to eq("cancel-01")
    end
  end

  describe "#initialize" do
    it "accepts a name parameter" do
      component = described_class.new(name: :crown)
      expect(component).to be_a(described_class)
    end

    it "accepts an optional class parameter" do
      component = described_class.new(name: :crown, class: "w-4 h-4")
      expect(component).to be_a(described_class)
    end

    it "accepts additional html_options" do
      component = described_class.new(name: :crown, class: "w-4 h-4", data: { testid: "crown-icon" })
      expect(component).to be_a(described_class)
    end
  end

  describe "#call" do
    it "renders an SVG element" do
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "renders the correct icon" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "applies custom class when provided" do
      rendered = render_inline(described_class.new(name: :crown, class: "w-4 h-4 text-accent"))
      expect(rendered).to have_css("svg.w-4.h-4.text-accent")
    end

    it "passes html_options to the icon helper" do
      rendered = render_inline(described_class.new(name: :crown, data: { testid: "crown-icon" }))
      expect(rendered).to have_css("svg[data-testid='crown-icon']")
    end

    it "raises ArgumentError for unknown icon names" do
      expect { render_inline(described_class.new(name: :unknown)) }
        .to raise_error(ArgumentError, "Unknown icon: unknown")
    end
  end

  describe "all icons render without error" do
    described_class::ICON_MAP.each_key do |name|
      it name.to_s do
        expect { render_inline(described_class.new(name: name)) }.not_to raise_error
      end
    end
  end
end
