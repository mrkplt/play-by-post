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

  it "passes an avatar_url through to render the avatar image instead of the monogram" do
    view = rendered(avatar_url: "/portrait.jpg")
    expect(view).to have_css("img[src='/portrait.jpg']")
    expect(view).not_to have_css("span[aria-hidden='true']", exact_text: "V")
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

    it "uses the large label scale for :lg" do
      expect(rendered(config: Config.new(size: :lg)).native.to_html).to include("text-[15px]")
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

  # The Config value object owns every state→CSS decision. Asserting the exact
  # class string each method emits (rather than a substring of rendered HTML)
  # pins the whole mapping down.
  describe Ui::IdentityBlockComponent::Config do
    describe "#wrapper_classes" do
      it "is the stacked orientation classes when active and :stacked" do
        expect(Config.new(orientation: :stacked, active: true).wrapper_classes)
          .to eq("flex flex-col items-center gap-[3px]")
      end

      it "is the inline orientation classes when active and :inline" do
        expect(Config.new(orientation: :inline, active: true).wrapper_classes)
          .to eq("flex items-center gap-2.5")
      end

      it "appends opacity-70 when inactive" do
        expect(Config.new(orientation: :inline, active: false).wrapper_classes)
          .to eq("flex items-center gap-2.5 opacity-70")
      end
    end

    describe "#labels_classes" do
      it "shrinks a beside-avatar column when :inline" do
        expect(Config.new(orientation: :inline).labels_classes).to eq("flex flex-col flex-1 min-w-0")
      end

      it "centers a stacked column when :stacked" do
        expect(Config.new(orientation: :stacked).labels_classes).to eq("flex flex-col items-center")
      end
    end

    describe "#primary_classes" do
      it "combines layout, size and colour, squished, for the inline default" do
        expect(Config.new(orientation: :inline, size: :md, variant: :default).primary_classes)
          .to eq("text-[13px] font-semibold text-ink")
      end

      it "centers the text for a stacked, uncrowned block" do
        expect(Config.new(orientation: :stacked, size: :sm, variant: :blue, crown: false).primary_classes)
          .to eq("text-center font-bold text-[11px] leading-tight text-tint-blue-strong")
      end

      it "lays the label as a flex row for a crowned block" do
        expect(Config.new(orientation: :stacked, size: :md, variant: :on_dark, crown: true).primary_classes)
          .to eq("flex items-center gap-1.5 text-[13px] font-semibold text-white")
      end
    end

    describe "#secondary_classes" do
      it "combines the secondary size and colour for :sm/:default" do
        expect(Config.new(size: :sm, variant: :default).secondary_classes).to eq("text-[11px] text-muted-2")
      end

      it "uses the blue-soft colour for :blue" do
        expect(Config.new(size: :md, variant: :blue).secondary_classes).to eq("text-[11px] text-tint-blue-soft")
      end

      it "uses the muted colour for :on_dark" do
        expect(Config.new(size: :md, variant: :on_dark).secondary_classes).to eq("text-[11px] text-muted")
      end
    end

    describe "#primary_classes for :lg" do
      it "combines the large layout, size and colour for the inline default" do
        expect(Config.new(orientation: :inline, size: :lg, variant: :on_dark).primary_classes)
          .to eq("text-[15px] font-semibold text-white")
      end
    end

    describe "#validate!" do
      it "names the offending orientation" do
        expect { Config.new(orientation: :sideways).validate! }
          .to raise_error(ArgumentError, "Unknown orientation: sideways")
      end

      it "names the offending variant" do
        expect { Config.new(variant: :neon).validate! }
          .to raise_error(ArgumentError, "Unknown variant: neon")
      end

      it "names the offending size" do
        expect { Config.new(size: :xl).validate! }
          .to raise_error(ArgumentError, "Unknown size: xl")
      end

      it "accepts a valid config" do
        expect { Config.new.validate! }.not_to raise_error
      end
    end
  end
end
