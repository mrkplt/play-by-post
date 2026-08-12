require "rails_helper"

RSpec.describe RssToken, type: :model do
  describe "associations" do
    it "belongs to user" do
      user = create(:user)
      token = create(:rss_token, user: user)
      expect(token.user).to eq(user)
    end

    it "belongs to game" do
      reflection = RssToken.reflect_on_association(:game)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.options[:optional]).to be_falsey
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

    it "declares user uniqueness scoped to game" do
      validator = RssToken.validators_on(:user_id)
        .find { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }

      expect(validator).to be_present
      expect(validator.options[:scope]).to eq(:game_id)
    end

    it "rejects a second token for the same user and game", db: true do
      user = create(:user)
      game = create(:game)
      create(:rss_token, user: user, game: game)

      duplicate = build(:rss_token, user: user, game: game)

      expect(duplicate).not_to be_valid
    end

    it "allows tokens for the same user in different games", db: true do
      user = create(:user)
      create(:rss_token, user: user, game: create(:game))

      other = build(:rss_token, user: user, game: create(:game))

      expect(other).to be_valid
    end
  end

  describe ".for_user_scope" do
    it "scopes by user and game" do
      user = build_stubbed(:user)
      game = build_stubbed(:game)

      expect(RssToken.for_user_scope(user, game).where_values_hash)
        .to eq("user_id" => user.id, "game_id" => game.id)
    end

    it "retrieves the matching token for a user and game", db: true do
      user = create(:user)
      game = create(:game)
      match = create(:rss_token, user: user, game: game)
      create(:rss_token, user: user, game: create(:game))
      create(:rss_token, user: create(:user), game: game)

      expect(RssToken.for_user_scope(user, game)).to contain_exactly(match)
    end
  end

  describe "token generation" do
    it "auto-generates token on create when not provided" do
      token = RssToken.create!(user: create(:user), game: create(:game))
      expect(token.token).to be_present
      expect(token.token.length).to eq(64)
    end

    it "does not overwrite a provided token" do
      provided = "a" * 64
      token = RssToken.create!(user: create(:user), game: create(:game), token: provided)
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
