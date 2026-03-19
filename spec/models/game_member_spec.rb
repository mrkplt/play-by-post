require "rails_helper"

RSpec.describe GameMember, type: :model do
  describe "validations" do
    it "requires a valid role" do
      member = build(:game_member, role: "invalid")
      expect(member).not_to be_valid
    end

    it "requires a valid status" do
      member = build(:game_member, status: "invalid")
      expect(member).not_to be_valid
    end

    it "is valid with defaults" do
      expect(build(:game_member)).to be_valid
    end
  end

  describe "predicates" do
    it "#game_master? returns true for game_master role" do
      expect(build(:game_member, :game_master).game_master?).to be true
    end

    it "#active? returns true for active status" do
      expect(build(:game_member).active?).to be true
    end

    it "#removed? returns true for removed status" do
      expect(build(:game_member, :removed).removed?).to be true
    end

    it "#banned? returns true for banned status" do
      expect(build(:game_member, :banned).banned?).to be true
    end
  end
end
