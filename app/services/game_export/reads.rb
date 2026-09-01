# typed: true

module GameExport
  # Every database read the export performs, each returning a plain array.
  # Specs covering rendered output stub these and hand back built records, so
  # only the reads themselves need a real connection.
  class Reads
    extend T::Sig

    sig { params(user: User).void }
    def initialize(user)
      @user = user
    end

    sig { params(game: Game).returns(T::Array[GameMember]) }
    def members_for(game)
      game.game_members.includes(:user).order(:role, :status).to_a
    end

    sig { params(game: Game).returns(T::Array[GameFile]) }
    def files_for(game)
      game.game_files.includes(file_attachment: :blob).order(:filename).to_a
    end

    sig { params(game: Game).returns(T::Array[Page]) }
    def pages_for(game)
      game.pages.order(:title).to_a
    end

    sig { params(game: Game).returns(T::Array[NotebookEntry]) }
    def notebook_entries_for(game)
      game.notebook_entries.order(:title).to_a
    end

    sig { params(game: Game).returns(T::Array[GameLink]) }
    def links_for(game)
      game.game_links.order(:description).to_a
    end

    sig { params(scene: Scene).returns(T::Array[SceneParticipant]) }
    def participants_for(scene)
      scene.scene_participants.includes(:user, :character).to_a
    end

    sig { params(scene: Scene).returns(T::Array[Post]) }
    def published_posts_for(scene)
      scene.posts.published.includes(:user).order(:created_at).to_a
    end

    # Every Versionable record (Character, Page, NotebookEntry) exposes its
    # snapshots through `versions`, so one read serves all three — each returns
    # its own version rows with the editor preloaded, oldest first.
    sig { params(record: T.untyped).returns(T::Array[T.untyped]) }
    def versions_for(record)
      record.versions.includes(:edited_by).order(:created_at).to_a
    end

    # Applies the export scope the policy decided (:all / :participating /
    # :visible). Each scope is its own method so the selection dispatches to one
    # rather than branching inside a single query builder.
    sig { params(game: Game, selection: Symbol).returns(T::Array[Scene]) }
    def scenes_for(game, selection)
      scope = SCENE_SCOPES.fetch(selection, :visible_scenes)

      with_scene_includes(send(scope, game)).to_a
    end

    sig { params(game: Game).returns(T.untyped) }
    def all_scenes(game)
      game.scenes
    end

    sig { params(game: Game).returns(T.untyped) }
    def participating_scenes(game)
      game.scenes.joins(:scene_participants).where(scene_participants: { user_id: @user.id })
    end

    sig { params(game: Game).returns(T.untyped) }
    def visible_scenes(game)
      Scene.visible_to(@user, game).where(game: game)
    end

    SCENE_SCOPES = T.let(
      { all: :all_scenes, participating: :participating_scenes }.freeze,
      T::Hash[Symbol, Symbol]
    )

    sig { params(game: Game, scenes: T::Array[Scene]).returns(T::Array[Character]) }
    def characters_for(game, scenes)
      participant_char_ids = SceneParticipant
        .where(scene_id: scenes.map(&:id))
        .where.not(character_id: nil)
        .pluck(:character_id)

      user_char_ids = game.characters.where(user: @user).pluck(:id)

      all_ids = (participant_char_ids + user_char_ids).uniq
      Character.where(id: all_ids).includes(:user, :character_versions).order(:name).to_a
    end

    # Every scene read preloads the same graph — the parent link, each
    # participant's user and character, and each post's author.
    sig { params(relation: T.untyped).returns(T.untyped) }
    def with_scene_includes(relation)
      relation.includes(:parent_scene, scene_participants: %i[user character], posts: :user)
    end
  end
end
