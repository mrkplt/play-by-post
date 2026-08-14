require "rails_helper"

RSpec.describe PagePresenter do
  let(:page) { build_stubbed(:page) }
  let(:game_policy) { instance_double(GamePolicy, manage?: true) }
  let(:page_policy) { instance_double(PagePolicy, manage?: true) }

  subject(:presenter) do
    described_class.new(page, game_policy: game_policy, page_policy: page_policy)
  end

  describe "#can_manage_game?" do
    it "is true when the injected game policy allows management" do
      allow(game_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage_game?).to be(true)
    end

    it "is false when the injected game policy disallows management" do
      allow(game_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage_game?).to be(false)
    end
  end

  describe "#can_manage?" do
    it "is true when the injected page policy allows management" do
      allow(page_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected page policy disallows management" do
      allow(page_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end
end
