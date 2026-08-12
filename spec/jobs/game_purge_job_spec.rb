require "rails_helper"

RSpec.describe GamePurgeJob, type: :job, db: true do
  # Builds a game with one record in every table tied to it and a stored artifact
  # on every attachable, so a purge can be shown to remove all of them — or, for a
  # second game, to leave all of them untouched. Filenames are suffixed so the two
  # games' blobs are distinguishable. Returns the record handles for assertions.
  def populate_game(suffix)
    game = create(:game)
    gm = create(:user)
    player = create(:user)
    records = { game: game }
    records[:memberships] = [
      create(:game_member, :game_master, game: game, user: gm),
      create(:game_member, game: game, user: player)
    ]
    records[:invitation] = create(:invitation, game: game, invited_by: gm)
    records[:character] = create(:character, game: game, user: player)
    records[:character_version] = create(:character_version, character: records[:character], edited_by: player)

    parent = create(:scene, game: game)
    child = create(:scene, game: game, parent_scene: parent)
    records[:scenes] = [ parent, child ]
    records[:scene_participant] = create(:scene_participant, scene: parent, user: player, character: records[:character])
    records[:scene_summary] = create(:scene_summary, scene: parent)
    records[:notification_preference] = create(:notification_preference, scene: parent, user: player)

    post = create(:post, scene: parent, user: player)
    records[:post] = post
    records[:post_read] = create(:post_read, post: post, user: player)
    records[:game_file] = create(:game_file, game: game)
    records[:page] = create(:page, game: game)
    records[:game_link] = create(:game_link, game: game)
    records[:notebook_entry] = create(:notebook_entry, game: game)
    records[:export] = create(:game_export_request, user: gm, game: game)
    records[:rss_token] = create(:rss_token, game: game, user: player)
    # An account-level token for the same user must survive the purge.
    records[:account_rss_token] = create(:rss_token, game: nil, user: player)

    parent.image.attach(io: StringIO.new("s"), filename: "scene-#{suffix}.png", content_type: "image/png")
    post.image.attach(io: StringIO.new("p"), filename: "post-#{suffix}.png", content_type: "image/png")
    records[:game_file].file.attach(io: StringIO.new("d"), filename: "doc-#{suffix}.txt", content_type: "text/plain")
    records[:export].archive.attach(io: StringIO.new("z"), filename: "export-#{suffix}.zip", content_type: "application/zip")

    records[:blob_filenames] = %W[scene-#{suffix}.png post-#{suffix}.png doc-#{suffix}.txt export-#{suffix}.zip]
    records
  end

  def record_present?(records)
    r = records
    Game.unscoped.exists?(r[:game].id) &&
      Scene.where(id: r[:scenes].map(&:id)).count == 2 &&
      Post.exists?(r[:post].id) && PostRead.exists?(r[:post_read].id) &&
      SceneParticipant.exists?(r[:scene_participant].id) &&
      SceneSummary.exists?(r[:scene_summary].id) &&
      NotificationPreference.exists?(r[:notification_preference].id) &&
      Character.exists?(r[:character].id) && CharacterVersion.exists?(r[:character_version].id) &&
      GameFile.exists?(r[:game_file].id) && Page.exists?(r[:page].id) &&
      GameLink.exists?(r[:game_link].id) &&
      NotebookEntry.exists?(r[:notebook_entry].id) &&
      Invitation.exists?(r[:invitation].id) &&
      GameMember.where(id: r[:memberships].map(&:id)).count == 2 &&
      GameExportRequest.exists?(r[:export].id) &&
      RssToken.exists?(r[:rss_token].id) &&
      ActiveStorage::Blob.where(filename: r[:blob_filenames]).count == 4
  end

  describe "#perform" do
    it "does nothing when the game no longer exists" do
      expect { described_class.new.perform(-1) }.not_to raise_error
    end

    it "leaves a game that is not soft-deleted untouched" do
      target = populate_game("live")

      described_class.new.perform(target[:game].id)

      expect(record_present?(target)).to be(true)
    end

    context "with a fully populated, soft-deleted game" do
      let!(:target) { populate_game("target") }
      let!(:survivor) { populate_game("survivor") }

      before { target[:game].soft_delete! }

      it "removes the game itself" do
        expect { described_class.new.perform(target[:game].id) }
          .to change { Game.unscoped.exists?(target[:game].id) }.from(true).to(false)
      end

      it "deletes every dependent record and purges every stored artifact" do
        described_class.new.perform(target[:game].id)

        expect(Scene.where(id: target[:scenes].map(&:id))).to be_empty
        expect(Post.where(id: target[:post].id)).to be_empty
        expect(PostRead.where(id: target[:post_read].id)).to be_empty
        expect(SceneParticipant.where(id: target[:scene_participant].id)).to be_empty
        expect(SceneSummary.where(id: target[:scene_summary].id)).to be_empty
        expect(NotificationPreference.where(id: target[:notification_preference].id)).to be_empty
        expect(Character.where(id: target[:character].id)).to be_empty
        expect(CharacterVersion.where(id: target[:character_version].id)).to be_empty
        expect(GameFile.where(id: target[:game_file].id)).to be_empty
        expect(Page.where(id: target[:page].id)).to be_empty
        expect(GameLink.where(id: target[:game_link].id)).to be_empty
        expect(NotebookEntry.where(id: target[:notebook_entry].id)).to be_empty
        expect(Invitation.where(id: target[:invitation].id)).to be_empty
        expect(GameMember.where(id: target[:memberships].map(&:id))).to be_empty
        expect(GameExportRequest.where(id: target[:export].id)).to be_empty
        expect(RssToken.where(id: target[:rss_token].id)).to be_empty
        expect(ActiveStorage::Blob.where(filename: target[:blob_filenames])).to be_empty
      end

      it "leaves the owner's account-level RSS token untouched" do
        described_class.new.perform(target[:game].id)

        expect(RssToken.where(id: target[:account_rss_token].id)).to be_present
      end

      it "leaves every other game's records and artifacts untouched" do
        described_class.new.perform(target[:game].id)

        expect(record_present?(survivor)).to be(true)
      end
    end

    context "when a record has no attachment" do
      it "purges what is attached and skips what is not, without error" do
        game = create(:game)
        scene = create(:scene, game: game)
        create(:post, scene: scene) # no image attached
        attached = create(:game_file, game: game)
        attached.file.attach(io: StringIO.new("d"), filename: "only.txt", content_type: "text/plain")
        game.soft_delete!

        expect { described_class.new.perform(game.id) }.not_to raise_error
        expect(Game.unscoped.exists?(game.id)).to be(false)
        expect(ActiveStorage::Blob.where(filename: "only.txt")).to be_empty
      end
    end
  end
end
