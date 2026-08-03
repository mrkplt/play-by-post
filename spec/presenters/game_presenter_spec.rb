require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }

  subject(:presenter) { described_class.new(game, user) }

  describe "#gm?" do
    it "is true when the viewer runs the game" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(presenter.gm?).to be(true)
    end

    it "is false when the viewer does not run the game" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(presenter.gm?).to be(false)
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end
end
