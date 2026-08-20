require "rails_helper"

RSpec.describe Ui::MarkdownRenderComponent, type: :component do
  def render_component(**overrides)
    render_inline(described_class.new(**{ text: "**bold**" }.merge(overrides)))
  end

  it "renders markdown as HTML inside the markdown-base region" do
    render_component(text: "# Heading\n\nSome **bold** text.")
    expect(page).to have_css("div.markdown-base h1", text: "Heading")
    expect(page).to have_css("div.markdown-base strong", text: "bold")
  end

  it "renders single newlines as line breaks" do
    render_component(text: "line one\nline two")
    expect(page).to have_css("div.markdown-base br")
  end

  it "strips script tags" do
    render_component(text: '<script>alert("xss")</script>')
    expect(page).not_to have_css("script")
  end

  it "renders an empty region when the text is blank" do
    render_component(text: "  ")
    expect(page).to have_css("div.markdown-base")
    expect(page.find("div.markdown-base").text).to eq("")
  end

  it "applies a named content class (a semantic style hook)" do
    render_component(content_class: "post-content")
    region = page.find("div.markdown-base")
    expect(region["class"]).to eq("markdown-base post-content")
  end

  it "applies the classes a named variant owns" do
    render_component(variant: :description)
    region = page.find("div.markdown-base")
    expect(region["class"]).to include("text-[13px]").and include("text-muted-2")
  end

  it "combines a variant and a named content class" do
    render_component(variant: :draft, content_class: "extra-hook")
    region = page.find("div.markdown-base")
    expect(region["class"]).to include("post-content").and include("extra-hook")
  end

  it "rejects an unknown variant" do
    expect { described_class.new(text: "x", variant: :bogus) }
      .to raise_error(ArgumentError, /Unknown variant/)
  end

  it "adds content attributes" do
    render_component(content_attributes: { data: { testid: "post-content" } })
    expect(page).to have_css("[data-testid='post-content']")
  end

  it "joins the classes into a single string" do
    component = described_class.new(text: "x")
    expect(component.classes).to eq("markdown-base")
  end

  describe "scroll config" do
    it "flows at its natural height by default" do
      render_component
      region = page.find("div.markdown-base")
      expect(region["style"]).to be_nil
      expect(region["class"]).to eq("markdown-base")
    end

    it "caps the height and scrolls when enabled" do
      render_component(config: described_class::Config.new(mode: :scroll, height: 200))
      region = page.find("div.markdown-base")
      expect(region["style"]).to eq("max-height: 200px")
      expect(region["class"]).to eq("markdown-base overflow-y-auto")
    end
  end

  describe described_class::Config do
    it "defaults to no scroll with a sensible height" do
      config = described_class.new
      expect(config.scroll).to be(false)
      expect(config.height).to eq(480)
    end

    it "rejects an unknown mode" do
      expect { described_class.new(mode: :unknown) }.to raise_error(ArgumentError, /Unknown mode/)
    end
  end
end
