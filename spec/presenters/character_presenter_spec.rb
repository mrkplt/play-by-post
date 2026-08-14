require "rails_helper"

RSpec.describe CharacterPresenter do
  let(:character) { build_stubbed(:character) }
  let(:game_policy) { instance_double(GamePolicy, manage?: true) }
  let(:character_policy) { instance_double(CharacterPolicy, update?: true, assign_owner?: true) }

  subject(:presenter) do
    described_class.new(character, game_policy: game_policy, character_policy: character_policy)
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

  describe "#can_edit?" do
    it "is true when the injected character policy allows update" do
      allow(character_policy).to receive(:update?).and_return(true)
      expect(presenter.can_edit?).to be(true)
    end

    it "is false when the injected character policy disallows update" do
      allow(character_policy).to receive(:update?).and_return(false)
      expect(presenter.can_edit?).to be(false)
    end
  end

  describe "#can_assign_owner?" do
    it "is true when the injected character policy allows assigning the owner" do
      allow(character_policy).to receive(:assign_owner?).and_return(true)
      expect(presenter.can_assign_owner?).to be(true)
    end

    it "is false when the injected character policy disallows assigning the owner" do
      allow(character_policy).to receive(:assign_owner?).and_return(false)
      expect(presenter.can_assign_owner?).to be(false)
    end
  end
end
