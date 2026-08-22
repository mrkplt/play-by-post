require "rails_helper"

RSpec.describe GameKeyAuthorizationPolicy do
  let(:game) { create(:game) }
  let(:owner) { create(:user) }

  def authorization_for(user)
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    build(:game_key_authorization, game: game, user: user, feature: "scene_summary")
  end

  describe "#contribute?" do
    it "permits a member managing their own authorization" do
      create(:game_member, game: game, user: owner)
      expect(described_class.new(owner, authorization_for(owner)).contribute?).to be(true)
    end

    it "denies managing someone else's authorization" do
      other = create(:user)
      create(:game_member, game: game, user: owner)
      create(:game_member, game: game, user: other)

      expect(described_class.new(owner, authorization_for(other)).contribute?).to be(false)
    end

    it "denies a non-member managing their own authorization" do
      expect(described_class.new(owner, authorization_for(owner)).contribute?).to be(false)
    end
  end

  describe "create?/destroy?" do
    it "delegate to contribute?" do
      create(:game_member, game: game, user: owner)
      policy = described_class.new(owner, authorization_for(owner))

      expect(policy.create?).to be(true)
      expect(policy.destroy?).to be(true)
    end

    it "deny when not the user's own record" do
      other = create(:user)
      create(:game_member, game: game, user: owner)
      policy = described_class.new(owner, authorization_for(other))

      expect(policy.create?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end
end
