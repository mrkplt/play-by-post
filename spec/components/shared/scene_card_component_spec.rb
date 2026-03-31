require "rails_helper"

RSpec.describe Shared::SceneCardComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) do
    build_stubbed(:scene,
      game: game,
      title: "The Tavern",
      updated_at: 2.days.ago)
  end
  let(:presenter) { ScenePresenter.new(scene) }

  subject(:component) { described_class.new(scene: presenter, game: game) }

  def rendered_component
    render_inline(component)
    page
  end

  before do
    allow(scene).to receive(:child_scenes).and_return([])
    allow(scene).to receive(:parent_scene).and_return(nil)
    allow(scene).to receive(:scene_participants).and_return(
      double(includes: [])
    )
  end

  it "renders the scene title" do
    expect(rendered_component).to have_text("The Tavern")
  end

  it "renders a link to the scene" do
    expect(rendered_component).to have_css("a", text: "The Tavern")
  end

  it "does not show private badge for public scene" do
    expect(rendered_component).not_to have_css("[data-variant=yellow]")
  end

  context "when private" do
    let(:scene) { build_stubbed(:scene, :private, game: game, title: "Secret Lair", updated_at: 1.day.ago) }

    before do
      allow(scene).to receive(:child_scenes).and_return([])
      allow(scene).to receive(:parent_scene).and_return(nil)
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [])
      )
    end

    it "shows the private badge" do
      expect(rendered_component).to have_css("[data-variant=yellow]", text: "Private")
    end
  end

  context "when the scene has a parent" do
    let(:parent) { build_stubbed(:scene, game: game, title: "Parent Scene") }
    let(:scene) { build_stubbed(:scene, game: game, title: "Child Scene", updated_at: 1.day.ago) }

    before do
      allow(scene).to receive(:child_scenes).and_return([])
      allow(scene).to receive(:parent_scene).and_return(parent)
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [])
      )
      allow(parent).to receive(:resolved?).and_return(false)
    end

    it "shows the parent scene link" do
      expect(rendered_component).to have_text("Parent Scene")
    end
  end
end
