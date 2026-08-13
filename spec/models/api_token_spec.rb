require "rails_helper"

RSpec.describe ApiToken, type: :model do
  describe "associations" do
    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "belongs to a game" do
      expect(described_class.reflect_on_association(:game).macro).to eq(:belongs_to)
    end
  end

  describe "token generation" do
    it "generates a 64-char hex token on create when none is given", :db do
      token = create(:api_token)
      expect(token.token).to match(/\A[0-9a-f]{64}\z/)
    end

    it "does not overwrite an explicitly provided token", :db do
      token = create(:api_token, token: "explicit-value")
      expect(token.token).to eq("explicit-value")
    end

    it "self.generate_secure_token returns a 64-char hex string" do
      expect(described_class.generate_secure_token).to match(/\A[0-9a-f]{64}\z/)
    end

    it "generates distinct tokens across calls" do
      expect(described_class.generate_secure_token).not_to eq(described_class.generate_secure_token)
    end
  end

  describe "#regenerate!" do
    it "replaces the token with a new secure value", :db do
      token = create(:api_token)
      original = token.token
      token.regenerate!
      expect(token.reload.token).not_to eq(original)
      expect(token.token).to match(/\A[0-9a-f]{64}\z/)
    end
  end

  describe "validations" do
    it "requires a scope" do
      token = build(:api_token, scope: nil)
      expect(token).not_to be_valid
      expect(token.errors[:scope]).to be_present
    end

    it "is unique per (user, scope, game)", :db do
      existing = create(:api_token)
      dup = build(:api_token, user: existing.user, game: existing.game, scope: existing.scope)
      expect(dup).not_to be_valid
      expect(dup.errors[:user_id]).to be_present
    end

    it "allows the same user a token in a different game", :db do
      existing = create(:api_token)
      other = build(:api_token, user: existing.user, scope: existing.scope)
      expect(other).to be_valid
    end

    it "allows the same user a different scope in the same game", :db do
      existing = create(:api_token)
      other = build(:api_token, user: existing.user, game: existing.game, scope: "api")
      expect(other).to be_valid
    end
  end
end
