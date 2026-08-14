# typed: false

require "rails_helper"

RSpec.describe Shared::GameDetailsComponent, type: :component do
  let(:game_model) { build_stubbed(:game, name: "Ashfall Reaches", description: "A grim frontier saga") }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }

  subject(:component) { described_class.new(game: game) }

  describe "#description?" do
    it "is true when the description is present" do
      expect(component.description?).to be(true)
    end

    it "is false when the description is blank" do
      game = GamePresenter.new(build_stubbed(:game, description: ""), policy: instance_double(GamePolicy))
      expect(described_class.new(game: game).description?).to be(false)
    end
  end

  it "renders the game name and an edit link" do
    render_inline(component)
    expect(page).to have_text("Ashfall Reaches")
    expect(page).to have_link("Edit", href: "/games/#{game_model.id}/edit")
  end

  it "renders the description as markdown, not escaped source" do
    game = GamePresenter.new(build_stubbed(:game, description: "A **grim** frontier saga"), policy: instance_double(GamePolicy))
    render_inline(described_class.new(game: game))
    expect(page).to have_css(".markdown-base strong", text: "grim")
  end

  it "shows a placeholder when the description is blank" do
    game = GamePresenter.new(build_stubbed(:game, description: ""), policy: instance_double(GamePolicy))
    render_inline(described_class.new(game: game))
    expect(page).to have_text("No description yet.")
  end
end
