require "rails_helper"

RSpec.describe GameFilePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:game_file) { build_stubbed(:game_file) }

  subject(:policy) { described_class.new(user, game_file) }

  before do
    allow(game_file).to receive(:game).and_return(game)
    # Defaults: not the GM, not an active member, contributions off, not the
    # author. Each example flips only the axis it exercises.
    allow(game).to receive(:game_master?).with(user).and_return(false)
    allow(game).to receive(:active_member?).with(user).and_return(false)
    allow(game).to receive(:player_contributions_enabled?).and_return(false)
    allow(game_file).to receive(:created_by?).with(user).and_return(false)
  end

  describe "#manage? (GM only)" do
    it "is true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.manage?).to be(true)
    end

    it "is false for a non-GM" do
      expect(policy.manage?).to be(false)
    end
  end

  describe "#create?" do
    it "is true for the GM regardless of the contributions setting" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.create?).to be(true)
    end

    it "is true for an active member when contributions are enabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.create?).to be(true)
    end

    it "is false for an active member when contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      expect(policy.create?).to be(false)
    end

    it "is false for a non-member even when contributions are enabled" do
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.create?).to be(false)
    end
  end

  describe "#destroy?" do
    it "is true for the GM even for a file they did not upload" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is true for a contributing active member who uploaded the file" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      allow(game_file).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is false for an active member who did not upload the file" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.destroy?).to be(false)
    end

    it "is false for the uploader once contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game_file).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(false)
    end
  end
end
