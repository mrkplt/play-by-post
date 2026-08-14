require "rails_helper"

RSpec.describe SceneRosterRowsPresenter do
  let(:scene) { build_stubbed(:scene, title: "The Ambush") }
  let(:scene_presenter) { ScenePresenter.new(scene) }

  subject(:presenter) { described_class.new(scene_presenter) }

  describe "#rows" do
    it "returns a name/scene row for each participant with a character" do
      character = build_stubbed(:character, name: "Vex")
      sp = double("scene_participant", character: character)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.rows).to eq([ { name: "Vex", scene: "The Ambush" } ])
    end

    it "excludes participants without a character" do
      sp = double("scene_participant", character: nil)
      allow(scene).to receive(:scene_participants).and_return([ sp ])

      expect(presenter.rows).to eq([])
    end
  end
end
