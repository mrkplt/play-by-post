require "rails_helper"

RSpec.describe Shared::SceneCardComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:scene) do
    build_stubbed(:scene, game: game, title: "The Tavern", updated_at: 2.days.ago)
  end
  let(:presenter) { ScenePresenter.new(scene) }

  subject(:component) { described_class.new(scene: presenter, game: game_presenter) }

  def rendered_component
    render_inline(component)
    page
  end

  before do
    allow(scene).to receive(:child_scenes).and_return([])
    allow(scene).to receive(:parent_scene).and_return(nil)
    allow(scene).to receive(:scene_participants).and_return(double(count: 3))
  end

  it "renders the scene title" do
    expect(rendered_component).to have_text("The Tavern")
  end

  it "renders a link to the scene" do
    expect(rendered_component).to have_css("a", text: "The Tavern")
  end

  it "shows the participant count" do
    expect(rendered_component).to have_text("3 participants")
  end

  it "singularizes a lone participant" do
    allow(scene).to receive(:scene_participants).and_return(double(count: 1))
    expect(rendered_component).to have_text("1 participant")
  end

  it "does not glow by default" do
    expect(rendered_component).not_to have_css(".is-hot")
  end

  it "glows when hot" do
    render_inline(described_class.new(scene: presenter, game: game_presenter, hot: true))
    expect(page).to have_css("div.attn-item.is-hot")
  end

  it "reports hot? state" do
    expect(described_class.new(scene: presenter, game: game_presenter, hot: true).hot?).to be true
    expect(described_class.new(scene: presenter, game: game_presenter).hot?).to be false
  end

  context "when the scene has a parent" do
    let(:parent) { build_stubbed(:scene, game: game, title: "Parent Scene") }

    before do
      allow(scene).to receive(:parent_scene).and_return(parent)
    end

    it "shows the parent scene title" do
      expect(rendered_component).to have_text("Parent Scene")
    end
  end

  context "when the scene has children in this game" do
    let(:child) { build_stubbed(:scene, game: game, title: "Child Scene") }

    before do
      allow(scene).to receive(:child_scenes).and_return([ child ])
    end

    it "lists the child scene" do
      expect(rendered_component).to have_text("Child Scene")
    end
  end
end
