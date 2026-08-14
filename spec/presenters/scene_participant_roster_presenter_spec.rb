require "rails_helper"

RSpec.describe SceneParticipantRosterPresenter do
  describe "#rows" do
    it "returns the underlying rows unchanged" do
      user = build_stubbed(:user)
      character = build_stubbed(:character)
      rows = [ [ UserPresenter.new(user), [ character ] ] ]

      presenter = described_class.new(rows, selected_character_ids: [])

      expect(presenter.rows).to eq(rows)
    end
  end

  describe "#selected_character_ids" do
    it "returns the injected selected ids" do
      presenter = described_class.new([], selected_character_ids: [ "1", "2" ])
      expect(presenter.selected_character_ids).to eq([ "1", "2" ])
    end

    it "raises when not supplied" do
      presenter = described_class.new([])
      expect { presenter.selected_character_ids }.to raise_error(KeyError)
    end
  end
end
