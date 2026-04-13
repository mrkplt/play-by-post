require "rails_helper"

RSpec.describe User, type: :model do
  describe "#display_name" do
    it "returns display_name from user_profile when profile exists" do
      user = create(:user, :with_profile)
      expect(user.display_name).to eq(user.user_profile.display_name)
    end

    it "returns nil when no profile exists" do
      user = create(:user)
      expect(user.display_name).to be_nil
    end
  end

  describe "associations" do
    it "has many game_members" do
      user = create(:user)
      game = create(:game)
      member = create(:game_member, user: user, game: game)
      expect(user.game_members).to include(member)
    end

    it "has many games through game_members" do
      user = create(:user)
      game = create(:game)
      create(:game_member, user: user, game: game)
      expect(user.games).to include(game)
    end
  end

end
