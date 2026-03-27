require "rails_helper"

RSpec.describe SceneParticipant, type: :model do
  describe "#display_name" do
    it "returns the character name when character is present" do
      character = create(:character, name: "Gandalf")
      participant = create(:scene_participant, character: character, user: character.user)
      expect(participant.display_name).to eq("Gandalf")
    end

    it "returns the user display name when no character and profile exists" do
      user = create(:user, :with_profile)
      participant = create(:scene_participant, user: user, character: nil)
      expect(participant.display_name).to eq(user.display_name)
    end

    it "returns the user email when no character and no display name" do
      user = create(:user)
      participant = create(:scene_participant, user: user, character: nil)
      expect(participant.display_name).to eq(user.email)
    end

    it "prefers character name over user display name" do
      user = create(:user, :with_profile)
      character = create(:character, name: "Frodo", user: user)
      participant = create(:scene_participant, user: user, character: character)
      expect(participant.display_name).to eq("Frodo")
    end
  end
end
