require "rails_helper"

RSpec.describe GamePurgeScope, type: :model, db: true do
  # A minimal record in every table GamePurgeScope operates over, so .for and
  # #delete_all_dependents! can be exercised directly (GamePurgeJob's own spec
  # covers the end-to-end purge including attachments; this spec is scoped to
  # the id-gathering and deletion behavior GamePurgeScope itself owns).
  def populate_game
    game = create(:game)
    player = create(:user)
    character = create(:character, game: game, user: player)
    scene = create(:scene, game: game)

    {
      game: game,
      character: character,
      scene: scene,
      character_version: create(:character_version, character: character, edited_by: player),
      scene_participant: create(:scene_participant, scene: scene, user: player, character: character),
      scene_summary: create(:scene_summary, scene: scene),
      notification_preference: create(:notification_preference, scene: scene, user: player),
      post: create(:post, scene: scene, user: player),
      game_file: create(:game_file, game: game)
    }
  end

  describe ".for" do
    it "collects the scene, post, and character ids belonging to the game" do
      records = populate_game
      other_game = create(:game)
      create(:scene, game: other_game)

      scope = described_class.for(records[:game])

      expect(scope.game).to eq(records[:game])
      expect(scope.scene_ids).to contain_exactly(records[:scene].id)
      expect(scope.post_ids).to contain_exactly(records[:post].id)
      expect(scope.character_ids).to contain_exactly(records[:character].id)
    end

    it "returns empty id sets for a game with nothing attached" do
      scope = described_class.for(create(:game))

      expect(scope.scene_ids).to eq([])
      expect(scope.post_ids).to eq([])
      expect(scope.character_ids).to eq([])
    end
  end

  describe "#game_id" do
    it "reads the id off the wrapped game" do
      game = create(:game)

      expect(described_class.for(game).game_id).to eq(game.id)
    end
  end

  describe "#delete_all_dependents!" do
    it "deletes every dependent record and the game itself" do
      records = populate_game
      scope = described_class.for(records[:game])

      scope.delete_all_dependents!

      expect(Game.unscoped.exists?(records[:game].id)).to be(false)
      expect(Scene.exists?(records[:scene].id)).to be(false)
      expect(Post.exists?(records[:post].id)).to be(false)
      expect(SceneParticipant.exists?(records[:scene_participant].id)).to be(false)
      expect(SceneSummary.exists?(records[:scene_summary].id)).to be(false)
      expect(NotificationPreference.exists?(records[:notification_preference].id)).to be(false)
      expect(Character.exists?(records[:character].id)).to be(false)
      expect(CharacterVersion.exists?(records[:character_version].id)).to be(false)
      expect(GameFile.exists?(records[:game_file].id)).to be(false)
    end

    it "leaves another game's records untouched" do
      records = populate_game
      survivor = populate_game

      described_class.for(records[:game]).delete_all_dependents!

      expect(Game.unscoped.exists?(survivor[:game].id)).to be(true)
      expect(Scene.exists?(survivor[:scene].id)).to be(true)
      expect(Post.exists?(survivor[:post].id)).to be(true)
    end

    it "breaks a scene's parent_scene_id link before deleting so the delete is FK-safe" do
      game = create(:game)
      parent = create(:scene, game: game)
      child = create(:scene, game: game, parent_scene: parent)

      expect { described_class.for(game).delete_all_dependents! }.not_to raise_error
      expect(Scene.where(id: [ parent.id, child.id ])).to be_empty
    end
  end
end
