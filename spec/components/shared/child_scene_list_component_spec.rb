require "rails_helper"

RSpec.describe Shared::ChildSceneListComponent, type: :component do
  let(:game_model) { build_stubbed(:game) }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }

  def build_component(child_scenes:)
    described_class.new(game: game, child_scenes: child_scenes.map { |c| ScenePresenter.new(c) })
  end

  it "renders nothing when there are no child scenes" do
    render_inline(build_component(child_scenes: []))
    expect(page).to have_no_css("a")
  end

  it "reports any? false for an empty list" do
    expect(build_component(child_scenes: []).any?).to be(false)
  end

  context "with child scenes" do
    let(:child) { build_stubbed(:scene, game: game_model, title: "The Aftermath") }

    it "reports any? true" do
      expect(build_component(child_scenes: [ child ]).any?).to be(true)
    end

    it "links to each child scene" do
      render_inline(build_component(child_scenes: [ child ]))
      expect(page).to have_link("The Aftermath", href: Rails.application.routes.url_helpers.game_scene_path(game_model, child))
    end

    it "links every child scene when there are several" do
      second = build_stubbed(:scene, game: game_model, title: "The Reckoning")
      render_inline(build_component(child_scenes: [ child, second ]))
      expect(page).to have_link("The Aftermath")
      expect(page).to have_link("The Reckoning")
    end
  end
end
