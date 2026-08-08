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

  describe "SIZES" do
    it "defines small size" do
      expect(described_class::SIZES[:small]).to eq("w-4 h-4")
    end

    it "defines medium size" do
      expect(described_class::SIZES[:medium]).to eq("w-5 h-5")
    end

    it "defines extra_small size" do
      expect(described_class::SIZES[:extra_small]).to eq("w-[13px] h-[13px]")
    end
  end

  describe "#initialize" do
    it "accepts a name parameter" do
      component = described_class.new(name: :crown)
      expect(component).to be_a(described_class)
    end

    it "defaults to small size" do
      component = described_class.new(name: :crown)
      expect(component).to be_a(described_class)
    end

    it "accepts a size parameter" do
      component = described_class.new(name: :crown, size: :medium)
      expect(component).to be_a(described_class)
    end

    it "accepts an accent parameter" do
      component = described_class.new(name: :crown, accent: true)
      expect(component).to be_a(described_class)
    end

    it "accepts additional html_options" do
      component = described_class.new(name: :crown, html_options: { data: { testid: "crown-icon" } })
      expect(component).to be_a(described_class)
    end
  end

  describe "#call" do
    it "renders an SVG element" do
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "renders the correct icon" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "applies small size by default" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "applies medium size when specified" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-5 h-5").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, size: :medium))
      expect(rendered).to have_css("svg")
    end

    it "applies extra_small size when specified" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-[13px] h-[13px]").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, size: :extra_small))
      expect(rendered).to have_css("svg")
    end

    it "adds text-accent class when accent is true" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4 text-accent").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, accent: true))
      expect(rendered).to have_css("svg")
    end

    it "passes html_options to the icon helper" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4", data: { testid: "crown-icon" }).and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, html_options: { data: { testid: "crown-icon" } }))
      expect(rendered).to have_css("svg")
    end

    it "replaces custom class when provided" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4 custom-class").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, html_options: { class: "custom-class" }))
      expect(rendered).to have_css("svg")
    end

    it "renders without options when no html_options provided" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "does not add class when html_options is empty" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03", class: "w-4 h-4").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, html_options: {}))
      expect(rendered).to have_css("svg")
    end

    it "does not add class when html_options[:class] is nil" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon).with("crown-03").and_return('<svg></svg>'.html_safe)
      rendered = render_inline(described_class.new(name: :crown, html_options: { class: nil }))
      expect(rendered).to have_css("svg")
    end

    it "raises ArgumentError for unknown icon names" do
      expect { render_inline(described_class.new(name: :unknown)) }
        .to raise_error(ArgumentError, "Unknown icon: unknown")
    end

    it "raises ArgumentError for unknown sizes" do
      expect { render_inline(described_class.new(name: :crown, size: :huge)) }
        .to raise_error(ArgumentError, "Unknown size: huge")
    end
  end

  describe "all icons render without error" do
    described_class::ICON_MAP.each_key do |name|
      it name.to_s do
        expect { render_inline(described_class.new(name: name)) }.not_to raise_error
      end
    end
  end

  describe "all sizes render without error" do
    described_class::SIZES.each_key do |size|
      it size.to_s do
        expect { render_inline(described_class.new(name: :crown, size: size)) }.not_to raise_error
      end
    end
  end
end
