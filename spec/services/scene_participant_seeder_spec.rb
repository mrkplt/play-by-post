require "rails_helper"

RSpec.describe SceneParticipantSeeder, :db do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  def seed(character_ids)
    described_class.new(scene, game).call(character_ids)
    scene.scene_participants.reload
  end

  it "adds the game master as a participant with no character" do
    participants = seed(nil)

    expect(participants.map(&:user_id)).to eq([ gm.id ])
    expect(T.must(participants.first).character_id).to be_nil
  end

  it "adds a selected character, deriving the user from the character" do
    character = create(:character, game: game, user: player)

    participants = seed([ character.id.to_s ])

    expect(participants.find_by(character_id: character.id).user_id).to eq(player.id)
  end

  it "ignores a character id that does not belong to the game" do
    other = create(:character, game: create(:game), user: player)

    participants = seed([ other.id.to_s ])

    expect(participants.map(&:user_id)).to eq([ gm.id ])
  end

  it "adds every selected character" do
    other_player = create(:user, :with_profile)
    create(:game_member, game: game, user: other_player)
    first = create(:character, game: game, user: player)
    second = create(:character, game: game, user: other_player)

    participants = seed([ first.id.to_s, second.id.to_s ])

    expect(participants.pluck(:character_id)).to include(first.id, second.id)
  end

  # The GM already has a user-only row from #add_game_master, and a participant
  # is unique per user — so selecting the GM's own character finds that row
  # rather than adding a second one for the character.
  it "does not add a second row for the game master's own character" do
    character = create(:character, game: game, user: gm)

    participants = seed([ character.id.to_s ])

    expect(participants.map(&:user_id)).to eq([ gm.id ])
  end

  it "does not duplicate a participant who is already in the scene" do
    create(:scene_participant, scene: scene, user: gm)

    expect { seed(nil) }.not_to change { scene.scene_participants.count }
  end
end
