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

    it "declares token uniqueness" do
      validator = RssToken.validators_on(:token)
        .find { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }

      expect(validator).to be_present
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
    it "replaces the token with a new value" do
      token_record = build(:rss_token)
      old_token = token_record.token

      token_record.regenerate!

      expect(token_record.token).not_to eq(old_token)
    end

    it "generates a valid 64-char hex token" do
      expect(RssToken.generate_secure_token).to match(/\A[0-9a-f]{64}\z/)
    end
  end

  describe ".generate_secure_token" do
    it "returns a 64-char hex string" do
      token = RssToken.generate_secure_token
      expect(token).to match(/\A[0-9a-f]{64}\z/)
    end
  end
end
