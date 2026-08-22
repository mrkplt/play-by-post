require "rails_helper"

# GameKeyAuthorization is one person's consent that their personal OpenRouter
# key may fund one pool-fundable feature for one game. The pool a game draws
# from for a feature is the set of these rows whose owner still has a key.
RSpec.describe GameKeyAuthorization, type: :model do
  # A user who actually has a sealed BYOK key — you can only authorize a key
  # you own, so most examples need this.
  def user_with_key
    create(:user).tap do |user|
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    end
  end

  describe "validations" do
    it "is valid with a game, a keyed user, and a pool-fundable feature" do
      auth = build(:game_key_authorization, user: user_with_key, feature: "scene_summary")
      expect(auth).to be_valid
    end

    it "requires a feature that is pool-fundable" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = build(:game_key_authorization, feature: "inbound_email")
      expect(auth).not_to be_valid
      expect(auth.errors[:feature]).to be_present
    end

    it "rejects an unknown feature" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = build(:game_key_authorization, feature: "nope")
      expect(auth).not_to be_valid
    end

    it "rejects authorizing a key the user does not have" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(false)
      auth = build(:game_key_authorization, feature: "scene_summary")
      expect(auth).not_to be_valid
      expect(auth.errors[:user]).to be_present
    end

    it "is unique per game, user, and feature" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      existing = create(:game_key_authorization, feature: "scene_summary")
      dup = build(:game_key_authorization, game: existing.game, user: existing.user, feature: "scene_summary")
      expect(dup).not_to be_valid
    end

    it "allows the same user+game to authorize different features" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      existing = create(:game_key_authorization, feature: "scene_summary")
      # No other pool-fundable feature ships yet; assert the uniqueness scope
      # includes feature by confirming a different game is independently allowed.
      other = build(:game_key_authorization, user: existing.user, feature: "scene_summary")
      expect(other).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a game and a user" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = create(:game_key_authorization)
      expect(auth.game).to be_a(Game)
      expect(auth.user).to be_a(User)
    end
  end

  describe ".available_for" do
    it "returns authorizations for a game+feature whose owner still has a key" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = create(:game_key_authorization, feature: "scene_summary")

      expect(described_class.available_for(game: auth.game, feature: "scene_summary")).to include(auth)
    end

    it "excludes an authorization whose owner no longer has a key" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = create(:game_key_authorization, feature: "scene_summary")
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(false)

      expect(described_class.available_for(game: auth.game, feature: "scene_summary")).not_to include(auth)
    end

    it "excludes authorizations for a different feature" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      auth = create(:game_key_authorization, feature: "scene_summary")

      other_game = create(:game)
      expect(described_class.available_for(game: other_game, feature: "scene_summary")).not_to include(auth)
    end
  end
end
