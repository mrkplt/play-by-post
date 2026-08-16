require "rails_helper"

RSpec.describe CharacterShowPresenter do
  let(:game) { build_stubbed(:game) }
  let(:character) { build_stubbed(:character, game: game) }

  subject(:presenter) { described_class.new(character) }

  describe "#owner" do
    it "wraps the character's user as a UserPresenter" do
      result = presenter.owner
      expect(result).to be_a(UserPresenter)
      expect(result.__getobj__).to eq(character.user)
    end
  end

  describe "#versions" do
    it "returns each character version, newest first, wrapped as presenters" do
      version = build_stubbed(:character_version)
      versions_rel = double("versions rel")
      ordered_rel = double("ordered rel")
      allow(character).to receive(:character_versions).and_return(versions_rel)
      allow(versions_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:includes).with(:edited_by).and_return([ version ])

      result = presenter.versions
      expect(result).to all(be_a(CharacterVersionPresenter))
      expect(result.map(&:__getobj__)).to eq([ version ])
    end
  end
end
