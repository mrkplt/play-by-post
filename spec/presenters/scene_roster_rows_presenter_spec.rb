require "rails_helper"

RSpec.describe SceneRosterRowsPresenter do
  let(:scene) { build_stubbed(:scene, title: "The Ambush") }
  let(:scene_presenter) { ScenePresenter.new(scene) }
  let(:helpers) { double("helpers", url_for: "/portrait.jpg") }

  subject(:presenter) { described_class.new(scene_presenter, helpers: helpers) }

  describe "#rows" do
    it "returns a name/scene/portrait row for each participant with a character" do
      character = build_stubbed(:character, name: "Vex")
      allow(character).to receive(:portrait_variant).and_return(:variant)
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.rows).to eq([ { name: "Vex", scene: "The Ambush", avatar_url: "/portrait.jpg" } ])
    end

    it "carries a nil avatar_url when the character has no portrait" do
      character = build_stubbed(:character, name: "Vex")
      allow(character).to receive(:portrait_variant).and_return(nil)
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.rows).to eq([ { name: "Vex", scene: "The Ambush", avatar_url: nil } ])
    end

    it "excludes participants without a character" do
      sp = double("scene_participant", character: nil)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.rows).to eq([])
    end
  end
end
