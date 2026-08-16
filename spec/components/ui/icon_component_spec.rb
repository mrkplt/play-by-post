require "rails_helper"

RSpec.describe Ui::IconComponent, type: :component do
  # Read instance state directly so default-value mutations (e.g. `size: nil`)
  # are observed even when Sorbet's runtime sig substitutes the mutated default
  # without raising. `build_options`/`call` are asserted on their real output.
  def ivar(component, name)
    component.instance_variable_get(name)
  end

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
    it "stores the name" do
      component = described_class.new(name: :crown)
      expect(ivar(component, :@name)).to eq(:crown)
    end

    it "defaults size to :small" do
      component = described_class.new(name: :crown)
      expect(ivar(component, :@size)).to eq(:small)
    end

    it "stores an explicit size" do
      component = described_class.new(name: :crown, size: :medium)
      expect(ivar(component, :@size)).to eq(:medium)
    end

    it "defaults emphasis to :normal" do
      component = described_class.new(name: :crown)
      expect(ivar(component, :@emphasis)).to eq(:normal)
    end

    it "stores an explicit emphasis" do
      component = described_class.new(name: :crown, emphasis: :accent)
      expect(ivar(component, :@emphasis)).to eq(:accent)
    end

    it "defaults html_options to an empty hash" do
      component = described_class.new(name: :crown)
      expect(ivar(component, :@html_options)).to eq({})
    end

    it "stores explicit html_options" do
      opts = { data: { testid: "crown-icon" } }
      component = described_class.new(name: :crown, html_options: opts)
      expect(ivar(component, :@html_options)).to eq(opts)
    end
  end

  describe "#build_options" do
    def build_options_for(**args)
      described_class.new(name: :crown, **args).send(:build_options)
    end

    it "returns only the size class by default" do
      expect(build_options_for).to eq(class: "w-4 h-4")
    end

    it "uses the medium size class" do
      expect(build_options_for(size: :medium)).to eq(class: "w-5 h-5")
    end

    it "appends text-accent when emphasis is :accent" do
      expect(build_options_for(emphasis: :accent)).to eq(class: "w-4 h-4 text-accent")
    end

    it "does not append text-accent when emphasis is :normal" do
      expect(build_options_for(emphasis: :normal)).to eq(class: "w-4 h-4")
    end

    it "appends a truthy custom class" do
      expect(build_options_for(html_options: { class: "custom-class" }))
        .to eq(class: "w-4 h-4 custom-class")
    end

    it "omits a nil custom class rather than joining it" do
      # Kills the `if custom_class` -> `if true` and `.compact` removal mutants:
      # a nil custom class must not append a trailing space or a "nil" token.
      expect(build_options_for(html_options: { class: nil })).to eq({})
    end

    it "merges extra html_options alongside the class" do
      expect(build_options_for(html_options: { data: { testid: "x" } }))
        .to eq(class: "w-4 h-4", data: { testid: "x" })
    end

    it "drops an empty class key entirely" do
      # With a nil custom class and no size contribution removed, `merged[:class]`
      # is blank and must be deleted (kills the `merged.delete(:class)` guard).
      expect(build_options_for(html_options: { class: nil })).not_to have_key(:class)
    end
  end

  describe "#call" do
    it "renders an SVG element" do
      rendered = render_inline(described_class.new(name: :crown))
      expect(rendered).to have_css("svg")
    end

    it "calls the icon helper with the mapped name and size class" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-4 h-4").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown))
    end

    it "applies medium size when specified" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-5 h-5").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown, size: :medium))
    end

    it "applies extra_small size when specified" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-[13px] h-[13px]").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown, size: :extra_small))
    end

    it "adds text-accent class when emphasis is :accent" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-4 h-4 text-accent").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown, emphasis: :accent))
    end

    it "passes html_options to the icon helper" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-4 h-4", data: { testid: "crown-icon" })
        .and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown, html_options: { data: { testid: "crown-icon" } }))
    end

    it "replaces custom class when provided" do
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-4 h-4 custom-class").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown, html_options: { class: "custom-class" }))
    end

    it "calls the icon helper WITHOUT keyword options when build_options is empty" do
      # Kills the `if options.empty?` -> `if nil`/`if false` and branch-collapse
      # mutants: an empty options hash must route through the no-kwargs call.
      component = described_class.new(name: :crown, html_options: { class: nil })
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03").and_return("<svg></svg>".html_safe)
      render_inline(component)
    end

    it "calls the icon helper WITH keyword options when build_options is non-empty" do
      # Kills the collapse to the always-kwargs branch: a non-empty options hash
      # must be splatted in.
      expect_any_instance_of(ApplicationHelper).to receive(:icon)
        .with("crown-03", class: "w-4 h-4").and_return("<svg></svg>".html_safe)
      render_inline(described_class.new(name: :crown))
    end

    it "raises ArgumentError for unknown icon names" do
      expect { render_inline(described_class.new(name: :unknown)) }
        .to raise_error(ArgumentError, "Unknown icon: unknown")
    end

    it "raises ArgumentError for unknown sizes" do
      expect { render_inline(described_class.new(name: :crown, size: :huge)) }
        .to raise_error(ArgumentError, "Unknown size: huge")
    end

    it "raises ArgumentError for unknown emphasis" do
      expect { described_class.new(name: :crown, emphasis: :bold) }
        .to raise_error(ArgumentError, "Unknown emphasis: bold")
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
