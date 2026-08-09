require "rails_helper"

RSpec.describe Shared::BreadcrumbsComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "The Sunken Archive") }

  it "links back to the game page" do
    render_inline(described_class.new(game: game))
    expect(page).to have_css("a", text: "The Sunken Archive")
  end

  it "links to the game's path" do
    render_inline(described_class.new(game: game))
    expect(page).to have_css("a[href='/games/#{game.id}']")
  end
end
