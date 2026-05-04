require "rails_helper"

RSpec.describe RssToken, type: :model do
  describe "associations" do
    it "belongs to user" do
      user = create(:user)
      token = create(:rss_token, user: user)
      expect(token.user).to eq(user)
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:rss_token)).to be_valid
    end

    it "requires token uniqueness" do
      existing = create(:rss_token)
      duplicate = build(:rss_token, token: existing.token)
      expect(duplicate).not_to be_valid
    end
  end

  describe "token generation" do
    it "auto-generates token on create when not provided" do
      user = create(:user)
      token = RssToken.create!(user: user)
      expect(token.token).to be_present
      expect(token.token.length).to eq(64)
    end

    it "does not overwrite a provided token" do
      provided = "a" * 64
      user = create(:user)
      token = RssToken.create!(user: user, token: provided)
      expect(token.token).to eq(provided)
    end
  end

  describe "#regenerate!" do
    it "replaces the token with a new unique value" do
      token_record = create(:rss_token)
      old_token = token_record.token
      token_record.regenerate!
      expect(token_record.reload.token).not_to eq(old_token)
    end

    it "generates a valid 64-char hex token" do
      token_record = create(:rss_token)
      token_record.regenerate!
      expect(token_record.reload.token).to match(/\A[0-9a-f]{64}\z/)
    end
  end

  describe ".generate_secure_token" do
    it "returns a 64-char hex string" do
      token = RssToken.generate_secure_token
      expect(token).to match(/\A[0-9a-f]{64}\z/)
    end
  end
end
