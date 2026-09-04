require "rails_helper"

RSpec.describe Ui::InfoLinkComponent, type: :component do
  def ivar(component, name)
    component.instance_variable_get(name)
  end

  def rendered(**opts)
    render_inline(described_class.new(**opts))
  end

  describe "#initialize" do
    it "stores the url" do
      expect(ivar(described_class.new(url: "/ai"), :@url)).to eq("/ai")
    end

    it "defaults the label to DEFAULT_LABEL" do
      expect(ivar(described_class.new(url: "/ai"), :@label)).to eq(described_class::DEFAULT_LABEL)
    end

    it "stores an explicit label" do
      expect(ivar(described_class.new(url: "/ai", label: "Learn more"), :@label)).to eq("Learn more")
    end
  end

  describe "rendering" do
    it "links to the given url" do
      expect(rendered(url: "/ai-control-plane")).to have_css("a[href='/ai-control-plane']")
    end

    it "renders the help icon" do
      expect(rendered(url: "/ai")).to have_css("a svg")
    end

    it "renders the default label text" do
      expect(rendered(url: "/ai")).to have_css("a span", text: described_class::DEFAULT_LABEL)
    end

    it "renders a custom label" do
      expect(rendered(url: "/ai", label: "Learn more")).to have_css("a span", text: "Learn more")
    end
  end

  describe "DEFAULT_LABEL" do
    it "is a non-empty string" do
      expect(described_class::DEFAULT_LABEL).to eq("How this works")
    end
  end
end
