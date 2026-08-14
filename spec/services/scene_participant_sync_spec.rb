require "rails_helper"

RSpec.describe SceneParticipantSync, db: true do
  let(:game) { create(:game) }
  let(:gm_user) { create(:user) }
  let!(:gm_member) { create(:game_member, :game_master, game: game, user: gm_user) }
  let(:scene) { create(:scene, game: game) }

  describe ".call" do
    it "creates the GM participant row even when no characters are selected" do
      described_class.call(scene: scene, characters: [])

      expect(scene.scene_participants.where(user_id: gm_user.id)).to exist
    end

    it "upserts a participant row for each selected character" do
      player = create(:user)
      create(:game_member, game: game, user: player, role: "player")
      character = create(:character, game: game, user: player)

      described_class.call(scene: scene, characters: [ character ])

      participant = scene.scene_participants.find_by(user_id: player.id)
      expect(participant).to be_present
      expect(participant.character).to eq(character)
    end

    it "removes player rows whose character is no longer selected, but keeps the GM row" do
      player = create(:user)
      create(:game_member, game: game, user: player, role: "player")
      character = create(:character, game: game, user: player)
      scene.scene_participants.create!(user: player, character: character)
      scene.scene_participants.create!(user: gm_user)

      described_class.call(scene: scene, characters: [])

      expect(scene.scene_participants.where(user_id: player.id)).not_to exist
      expect(scene.scene_participants.where(user_id: gm_user.id)).to exist
    end

    it "updates an existing participant row's character rather than duplicating it" do
      player = create(:user)
      create(:game_member, game: game, user: player, role: "player")
      old_character = create(:character, game: game, user: player, name: "Old")
      new_character = create(:character, game: game, user: player, name: "New")
      scene.scene_participants.create!(user: player, character: old_character)
      scene.scene_participants.create!(user: gm_user)

      expect do
        described_class.call(scene: scene, characters: [ new_character ])
      end.not_to change { scene.scene_participants.count }

      expect(scene.scene_participants.find_by(user_id: player.id).character).to eq(new_character)
    end
  end
end
