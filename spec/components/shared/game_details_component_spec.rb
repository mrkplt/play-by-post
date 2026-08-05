# typed: false

require "rails_helper"

RSpec.describe Shared::GameDetailsComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches", description: "A grim frontier saga") }

  subject(:component) { described_class.new(game: game) }

  describe "#description?" do
    it "is true when the description is present" do
      expect(component.description?).to be(true)
    end

    it "is false when the description is blank" do
      game = build_stubbed(:game, description: "")
      expect(described_class.new(game: game).description?).to be(false)
    end
  end

  describe "#rendered_description" do
    it "renders markdown emphasis as HTML" do
      game = build_stubbed(:game, description: "A **grim** saga")
      html = described_class.new(game: game).rendered_description
      expect(html).to include("<strong>grim</strong>")
    end

    it "renders single newlines as line breaks" do
      game = build_stubbed(:game, description: "line one\nline two")
      html = described_class.new(game: game).rendered_description
      expect(html).to include("<br>")
    end
  end

  it "renders the game name and an edit link" do
    render_inline(component)
    expect(page).to have_text("Ashfall Reaches")
    expect(page).to have_link("Edit", href: "/games/#{game.id}/edit")
  end

  it "renders the description as markdown, not escaped source" do
    game = build_stubbed(:game, description: "A **grim** frontier saga")
    render_inline(described_class.new(game: game))
    expect(page).to have_css(".markdown-base strong", text: "grim")
  end

  it "shows a placeholder when the description is blank" do
    game = build_stubbed(:game, description: "")
    render_inline(described_class.new(game: game))
    expect(page).to have_text("No description yet.")
  end
end
