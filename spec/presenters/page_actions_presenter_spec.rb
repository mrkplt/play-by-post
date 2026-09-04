require "rails_helper"

RSpec.describe PageActionsPresenter do
  let(:page_record) { build_stubbed(:page) }
  let(:policy) { instance_double(PagePolicy, manage?: false, update?: false, destroy?: false) }
  let(:game_policy) { instance_double(GamePolicy, manage?: false) }

  subject(:presenter) { described_class.new(page_record, game_policy: game_policy, page_policy: policy) }

  describe "#can_manage_game?" do
    it "reflects the injected game policy's #manage?" do
      allow(game_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage_game?).to be(true)
    end

    it "is false when the game policy disallows management" do
      allow(game_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage_game?).to be(false)
    end
  end

  describe "#can_manage?" do
    it "reflects the injected page policy's #manage?" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the page policy disallows management" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#can_edit?" do
    it "reflects the injected page policy's #update?" do
      allow(policy).to receive(:update?).and_return(true)
      expect(presenter.can_edit?).to be(true)
    end

    it "is false when the policy disallows editing" do
      allow(policy).to receive(:update?).and_return(false)
      expect(presenter.can_edit?).to be(false)
    end
  end

  describe "#can_delete?" do
    it "reflects the injected page policy's #destroy?" do
      allow(policy).to receive(:destroy?).and_return(true)
      expect(presenter.can_delete?).to be(true)
    end

    it "is false when the policy disallows deletion" do
      allow(policy).to receive(:destroy?).and_return(false)
      expect(presenter.can_delete?).to be(false)
    end
  end
end
