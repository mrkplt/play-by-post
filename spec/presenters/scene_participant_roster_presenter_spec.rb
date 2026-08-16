require "rails_helper"

RSpec.describe SceneParticipantRosterPresenter do
  describe "#selected_character_ids" do
    it "returns the injected character ids as strings, preserving order" do
      presenter = described_class.new([ 3, 1, 2 ])
      expect(presenter.selected_character_ids).to eq([ "3", "1", "2" ])
    end

    it "is empty when there are no selected characters" do
      presenter = described_class.new([])
      expect(presenter.selected_character_ids).to eq([])
    end
  end

  describe "#players_with_characters" do
    it "returns the injected players_with_characters option" do
      players = [ instance_double(ScenePlayerPresenter) ]
      presenter = described_class.new([], players_with_characters: players)
      expect(presenter.players_with_characters).to eq(players)
    end
  end
end
