require "rails_helper"

RSpec.describe GameExport::Reads, :db do
  let(:gm_user) { create(:user, :with_profile) }
  let(:player_user) { create(:user, :with_profile) }
  let(:game) { create(:game, name: "Test Game", description: "A test game.") }
  let!(:gm_member) { create(:game_member, :game_master, game: game, user: gm_user) }
  let!(:player_member) { create(:game_member, game: game, user: player_user) }
  let(:scene) { create(:scene, game: game, title: "Opening Scene") }
  let!(:participant) { create(:scene_participant, scene: scene, user: player_user) }
  let!(:post) { create(:post, scene: scene, user: player_user, content: "Hello world!") }

  # Zip assembly with every read stubbed: entry paths and slugging are the
  # service's own doing, so they need built records, not persisted ones.
  # Which scenes a membership exports is a pure rule; the query only applies it.
  # The reads are stubbed everywhere above, so nothing else executes their query
  # chains — cover them directly or every mutation of them survives.
  describe "reads" do
    let(:service) { GameExport::Reads.new(reader) }
    let(:reader) { build_stubbed(:user) }

    def chain
      double.tap do |c|
        allow(c).to receive(:includes).and_return(c)
        allow(c).to receive(:order).and_return(c)
        allow(c).to receive(:joins).and_return(c)
        allow(c).to receive(:where).and_return(c)
        allow(c).to receive(:not).and_return(c)
        allow(c).to receive(:to_a).and_return([])
      end
    end

    it "loads members with their user, ordered by role then status" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_members).and_return(c)

      service.send(:members_for, game)

      expect(c).to have_received(:includes).with(:user)
      expect(c).to have_received(:order).with(:role, :status)
    end

    it "loads files with their blob, ordered by filename" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_files).and_return(c)

      service.send(:files_for, game)

      expect(c).to have_received(:includes).with(file_attachment: :blob)
      expect(c).to have_received(:order).with(:filename)
    end

    it "loads pages ordered by title" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:pages).and_return(c)

      service.send(:pages_for, game)

      expect(c).to have_received(:order).with(:title)
    end

    it "loads notebook entries ordered by title" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:notebook_entries).and_return(c)

      service.send(:notebook_entries_for, game)

      expect(c).to have_received(:order).with(:title)
    end

    it "loads links ordered by description" do
      game = build_stubbed(:game)
      c = chain
      allow(game).to receive(:game_links).and_return(c)

      service.send(:links_for, game)

      expect(c).to have_received(:order).with(:description)
    end

    it "loads participants with their user and character" do
      scene = build_stubbed(:scene)
      c = chain
      allow(scene).to receive(:scene_participants).and_return(c)

      service.send(:participants_for, scene)

      expect(c).to have_received(:includes).with(:user, :character)
    end

    it "loads published posts with their user, oldest first" do
      scene = build_stubbed(:scene)
      c = chain
      allow(scene).to receive(:posts).and_return(double(published: c))

      service.send(:published_posts_for, scene)

      expect(c).to have_received(:includes).with(:user)
      expect(c).to have_received(:order).with(:created_at)
    end

    it "loads versions with their editor, oldest first" do
      character = build_stubbed(:character)
      c = chain
      allow(character).to receive(:character_versions).and_return(c)

      service.send(:versions_for, character)

      expect(c).to have_received(:includes).with(:edited_by)
      expect(c).to have_received(:order).with(:created_at)
    end

    it "loads page versions with their editor, oldest first" do
      page = build_stubbed(:page)
      c = chain
      allow(page).to receive(:page_versions).and_return(c)

      service.send(:page_versions_for, page)

      expect(c).to have_received(:includes).with(:edited_by)
      expect(c).to have_received(:order).with(:created_at)
    end

    it "loads notebook entry versions with their editor, oldest first" do
      entry = build_stubbed(:notebook_entry)
      c = chain
      allow(entry).to receive(:notebook_entry_versions).and_return(c)

      service.send(:notebook_entry_versions_for, entry)

      expect(c).to have_received(:includes).with(:edited_by)
      expect(c).to have_received(:order).with(:created_at)
    end

    describe "#characters_for" do
      let(:export_game) { build_stubbed(:game) }
      let(:export_scene) { build_stubbed(:scene) }

      before do
        participants = chain
        allow(participants).to receive(:pluck).and_return([ 7 ])
        allow(SceneParticipant).to receive(:where).and_return(participants)

        owned = chain
        allow(owned).to receive(:pluck).and_return([ 9 ])
        allow(export_game).to receive(:characters).and_return(double(where: owned))

        @found = chain
        allow(Character).to receive(:where).and_return(@found)
      end

      it "combines participant characters with the viewer's own, deduped and ordered" do
        service.send(:characters_for, export_game, [ export_scene ])

        expect(Character).to have_received(:where).with(id: [ 7, 9 ])
        expect(@found).to have_received(:includes).with(:user, :character_versions)
        expect(@found).to have_received(:order).with(:name)
      end

      it "ignores participants with no character" do
        service.send(:characters_for, export_game, [ export_scene ])

        expect(SceneParticipant).to have_received(:where).with(scene_id: [ export_scene.id ])
      end
    end
  end

  # Which membership gets which scenes is exactly what the query has to select
  # on: a real, persisted graph is needed so a wrong join, where clause, or
  # branch actually changes what comes back — a stubbed relation can't fail
  # this the way a real one does.
  describe "#export_scenes_for" do
    let(:service) { GameExport::Reads.new(player_user) }

    it "gives the GM every scene in the game, including private ones" do
      secret = create(:scene, :private, game: game, title: "Secret Room")

      result = GameExport::Reads.new(gm_user).send(:scenes_for, game, :all)

      expect(result).to contain_exactly(scene, secret)
    end

    it "limits a removed member to scenes they participated in" do
      removed_user = create(:user, :with_profile)
      removed_member = create(:game_member, :removed, game: game, user: removed_user)
      create(:scene_participant, scene: scene, user: removed_user)
      elsewhere = create(:scene, game: game, title: "Elsewhere")

      result = GameExport::Reads.new(removed_user).send(:scenes_for, game, :participating)

      expect(result).to contain_exactly(scene)
      expect(result).not_to include(elsewhere)
    end

    it "gives an active player the scenes visible to them, not private ones they're not in" do
      create(:scene, :private, game: game, title: "Secret Room")

      result = service.send(:scenes_for, game, :visible)

      expect(result).to contain_exactly(scene)
    end

    it "scopes visible scenes to the requested game, not every game the viewer can see" do
      other_game = create(:game, name: "Other Game")
      create(:game_member, game: other_game, user: player_user, role: "player", status: "active")
      create(:scene, game: other_game, title: "Elsewhere Entirely")

      result = service.send(:scenes_for, game, :visible)

      expect(result).to contain_exactly(scene)
    end
  end
end
