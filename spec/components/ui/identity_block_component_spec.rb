require "rails_helper"

RSpec.describe Ui::IdentityBlockComponent, type: :component do
  Config = Ui::IdentityBlockComponent::Config

  def rendered(config: Config.new, **labels)
    defaults = { name: "Vex Marrowgate", primary: "Vex Marrowgate", secondary: "Played by Dana" }
    render_inline(described_class.new(config: config, **defaults.merge(labels)))
    page
  end

  it "renders the avatar monogram from the name" do
    expect(rendered).to have_css("span", text: "V")
  end

  it "renders the primary and secondary labels" do
    r = rendered
    expect(r).to have_text("Vex Marrowgate")
    expect(r).to have_text("Played by Dana")
  end

  describe "orientation" do
    it "stacks and centers labels when :stacked" do
      expect(rendered(config: Config.new(orientation: :stacked)).find("div", match: :first)[:class])
        .to include("flex-col").and include("items-center")
    end

    it "lays labels beside the avatar when :inline" do
      expect(rendered(config: Config.new(orientation: :inline)).find("div", match: :first)[:class])
        .to include("items-center")
    end

    it "rejects an unknown orientation" do
      expect { described_class.new(name: "x", primary: "x", secondary: "y", config: Config.new(orientation: :sideways)) }
        .to raise_error(ArgumentError, /Unknown orientation/)
    end
  end

  describe "variant (colour)" do
    it "uses ink/muted tokens by default" do
      html = rendered.native.to_html
      expect(html).to include("text-ink").and include("text-muted-2")
    end

    it "uses blue-tint tokens for :blue" do
      html = rendered(config: Config.new(variant: :blue)).native.to_html
      expect(html).to include("text-tint-blue-strong").and include("text-tint-blue-soft")
    end

    it "uses on-dark tokens for :on_dark" do
      html = rendered(config: Config.new(variant: :on_dark)).native.to_html
      expect(html).to include("text-white").and include("text-muted")
    end

    it "rejects an unknown variant" do
      expect { described_class.new(name: "x", primary: "x", secondary: "y", config: Config.new(variant: :neon)) }
        .to raise_error(ArgumentError, /Unknown variant/)
    end
  end

  describe "size" do
    it "uses the small label scale for :sm" do
      expect(rendered(config: Config.new(size: :sm)).native.to_html).to include("text-[11px]")
    end

    it "uses the medium label scale for :md" do
      expect(rendered(config: Config.new(size: :md)).native.to_html).to include("text-[13px]")
    end

    it "rejects an unknown size" do
      expect { described_class.new(name: "x", primary: "x", secondary: "y", config: Config.new(size: :xl)) }
        .to raise_error(ArgumentError, /Unknown size/)
    end
  end

  describe "crown" do
    it "renders a crown icon when crowned" do
      expect(rendered(config: Config.new(crown: true))).to have_css("svg, img", minimum: 1)
    end

    it "reports crown? false by default" do
      expect(described_class.new(name: "x", primary: "x", secondary: "y").crown?).to be false
    end
  end

  describe "active state" do
    it "dims the cluster when inactive" do
      expect(rendered(config: Config.new(active: false)).native.to_html).to include("opacity-70")
    end

    it "is not dimmed when active" do
      expect(rendered(config: Config.new(active: true)).native.to_html).not_to include("opacity-70")
    end
  end

  describe "secondary label safety" do
    it "renders an html_safe secondary label as markup" do
      r = rendered(secondary: "<time datetime='x'>2 days ago</time>".html_safe)
      expect(r).to have_css("time", text: "2 days ago")
    end

    it "escapes a plain-string secondary label as text" do
      r = rendered(secondary: "<b>plain</b>")
      expect(r).to have_no_css("b")
      expect(r).to have_text("<b>plain</b>")
    end
  end
end
