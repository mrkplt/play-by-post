require "rails_helper"

RSpec.describe GamePurgeDeletion, type: :model, db: true do
  # A minimal record in every table the deletion touches, so #delete_all! can be
  # exercised directly. GamePurgeJob's own spec covers the end-to-end purge
  # including attachments; this spec is scoped to the deletion order.
  def populate_game
    game = create(:game)
    player = create(:user)
    character = create(:character, game: game, user: player)
    scene = create(:scene, game: game)
    summary = create(:scene_summary, scene: scene)

    {
      game: game, character: character, scene: scene, summary: summary,
      character_version: create(:character_version, character: character, edited_by: player),
      scene_participant: create(:scene_participant, scene: scene, user: player, character: character),
      summary_version: summary.scene_summary_versions.first!,
      notification_preference: create(:notification_preference, scene: scene, user: player),
      post: create(:post, scene: scene, user: player),
      game_file: create(:game_file, game: game),
      notebook_entry: notebook_entry = create(:notebook_entry, game: game, editor: player),
      notebook_entry_version: notebook_entry.notebook_entry_versions.first!
    }
  end

  def delete!(game)
    described_class.new(GamePurgeScope.for(game)).delete_all!
  end

  it "deletes every dependent record and the game itself" do
    r = populate_game

    delete!(r[:game])

    expect(Game.unscoped.exists?(r[:game].id)).to be(false)
    expect(Scene.exists?(r[:scene].id)).to be(false)
    expect(Post.exists?(r[:post].id)).to be(false)
    expect(SceneParticipant.exists?(r[:scene_participant].id)).to be(false)
    expect(SceneSummary.exists?(r[:summary].id)).to be(false)
    expect(SceneSummaryVersion.exists?(r[:summary_version].id)).to be(false)
    expect(NotificationPreference.exists?(r[:notification_preference].id)).to be(false)
    expect(Character.exists?(r[:character].id)).to be(false)
    expect(CharacterVersion.exists?(r[:character_version].id)).to be(false)
    expect(GameFile.exists?(r[:game_file].id)).to be(false)
    expect(NotebookEntry.exists?(r[:notebook_entry].id)).to be(false)
    expect(NotebookEntryVersion.exists?(r[:notebook_entry_version].id)).to be(false)
  end

  it "deletes scene summary versions before their summaries (FK-safe)" do
    r = populate_game

    expect { delete!(r[:game]) }.not_to raise_error
    expect(SceneSummaryVersion.exists?(r[:summary_version].id)).to be(false)
  end

  it "deletes notebook entry versions before their entries (FK-safe)" do
    r = populate_game

    expect { delete!(r[:game]) }.not_to raise_error
    expect(NotebookEntryVersion.exists?(r[:notebook_entry_version].id)).to be(false)
  end

  it "leaves another game's records untouched" do
    r = populate_game
    survivor = populate_game

    delete!(r[:game])

    expect(Game.unscoped.exists?(survivor[:game].id)).to be(true)
    expect(Scene.exists?(survivor[:scene].id)).to be(true)
    expect(SceneSummaryVersion.exists?(survivor[:summary_version].id)).to be(true)
  end

  it "breaks a scene's parent_scene_id link before deleting so the delete is FK-safe" do
    game = create(:game)
    parent = create(:scene, game: game)
    child = create(:scene, game: game, parent_scene: parent)

    expect { delete!(game) }.not_to raise_error
    expect(Scene.where(id: [ parent.id, child.id ])).to be_empty
  end
end
