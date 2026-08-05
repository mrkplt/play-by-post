# typed: false

require "rails_helper"

RSpec.describe Shared::SceneResolutionComponent, type: :component do
  describe "#rendered_resolution" do
    it "renders markdown emphasis as HTML" do
      scene = build_stubbed(:scene, resolution: "The party **won**")
      html = described_class.new(scene: scene).rendered_resolution
      expect(html).to include("<strong>won</strong>")
    end

    it "renders single newlines as line breaks" do
      scene = build_stubbed(:scene, resolution: "line one\nline two")
      html = described_class.new(scene: scene).rendered_resolution
      expect(html).to include("<br>")
    end
  end

  it "renders the resolution as markdown inside a labelled card" do
    scene = build_stubbed(:scene, resolution: "The dragon **fell**")
    render_inline(described_class.new(scene: scene))

    expect(page).to have_text("Resolution:")
    expect(page).to have_css(".markdown-base strong", text: "fell")
  end
end
