require "rails_helper"

RSpec.describe Shared::BreadcrumbsComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "The Sunken Archive") }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  it "links back to the game page" do
    render_inline(described_class.new(game_presenter: game_presenter))
    expect(page).to have_css("a", text: "The Sunken Archive")
  end

  it "links to the game's path" do
    render_inline(described_class.new(game_presenter: game_presenter))
    expect(page).to have_css("a[href='/games/#{game.to_param}']")
  end
end
