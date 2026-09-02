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
      game_file: create(:game_file, game: game),
      notebook_entry: notebook_entry = create(:notebook_entry, game: game, editor: player),
      notebook_entry_version: notebook_entry.notebook_entry_versions.first!
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

  # The deletion order lives in GamePurgeDeletion (see its own spec); the scope
  # only delegates to it. Kept as one end-to-end assertion that the delegation
  # actually purges, so the wiring can't silently break.
  describe "#delete_all_dependents!" do
    it "delegates to GamePurgeDeletion and purges the game" do
      records = populate_game

      described_class.for(records[:game]).delete_all_dependents!

      expect(Game.unscoped.exists?(records[:game].id)).to be(false)
      expect(Scene.exists?(records[:scene].id)).to be(false)
    end
  end
end
