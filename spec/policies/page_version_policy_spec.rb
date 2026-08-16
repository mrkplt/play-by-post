require "rails_helper"

RSpec.describe PageVersionPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:page_record) { instance_double(Page) }
  let(:version) { build_stubbed(:page_version) }

  subject(:policy) { described_class.new(user, version) }

  before do
    allow(version).to receive(:page).and_return(page_record)
    allow(page_record).to receive(:game).and_return(game)
  end

  describe "#show?" do
    context "for a version of a published page (game access)" do
      before { allow(page_record).to receive(:draft?).and_return(false) }

      it "is true when the game is viewable by the user" do
        allow(game).to receive(:viewable_by?).with(user).and_return(true)
        expect(policy.show?).to be(true)
      end

      it "is false when the game is not viewable by the user" do
        allow(game).to receive(:viewable_by?).with(user).and_return(false)
        expect(policy.show?).to be(false)
      end

      it "routes through GamePolicy for the page's game" do
        game_policy = instance_double(GamePolicy, view?: true)
        allow(GamePolicy).to receive(:new).with(user, game).and_return(game_policy)
        expect(policy.show?).to be(true)
        expect(GamePolicy).to have_received(:new).with(user, game)
      end
    end

    context "for a version of a draft page (manager only)" do
      before { allow(page_record).to receive(:draft?).and_return(true) }

      it "is true for the GM" do
        allow(game).to receive(:game_master?).with(user).and_return(true)
        expect(policy.show?).to be(true)
      end

      it "is false for a non-GM even when the game is viewable" do
        allow(game).to receive(:game_master?).with(user).and_return(false)
        expect(policy.show?).to be(false)
      end
    end
  end
end
