# typed: strict

# View model for the game screen's tab panels (GamesController#show):
# active scenes, the roster preview, the character roster, and the files
# list. Split out from GamePresenter (used by every game-scoped screen) so
# that presenter stays small; this one wraps a GamePresenter — a presenter
# subject is a legal BasePresenter subject alongside a model — plus the
# viewer, and delegates capability/collection questions that don't need
# viewer-scoping straight to it.
class GameShowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @model.can_manage?
  end

  # The game's active scenes visible to the viewer, most recently active
  # first — the Scenes panel's card list. Each scene is aware of whether it
  # counts as "hot" (activity since the viewer's last login), via
  # ScenePresenter#hot? reading the same hot_scene_ids this presenter derives.
  sig { returns(T::Array[ScenePresenter]) }
  def active_scenes
    hot_ids = hot_scene_ids
    raw_active_scenes.map { |s| ScenePresenter.new(s, hot_scene_ids: hot_ids) }
  end

  # The GM's display name — always shown, crowned, at the top of the "In
  # Active Scenes" roster preview.
  sig { returns(String) }
  def gm_name
    gm = game.game_members.game_masters.includes(:user).first&.user
    gm ? UserPresenter.new(gm).display_name_or_email : "GM"
  end

  # The "In Active Scenes" roster preview: the GM, then up to five distinct
  # characters participating in an active scene, each paired with that
  # scene's title. Banned players are already excluded from scene
  # participation.
  sig { returns(T::Array[T::Hash[Symbol, String]]) }
  def roster_preview
    rows = raw_active_scenes.flat_map do |scene|
      scene.scene_participants.filter_map do |sp|
        next unless sp.character

        { name: T.must(sp.character).name, scene: scene.title }
      end
    end
    rows.uniq { |r| r[:name] }.first(5)
  end

  # Active characters visible to the viewer, one presenter per row, for the
  # Roster tab's character list.
  sig { returns(T::Array[RosterCharacterPresenter]) }
  def roster_characters
    removed_user_ids = game.game_members.where(status: "removed").pluck(:user_id).to_set

    game.characters.active.visible_to(viewer, game).includes(:user).order(:name).to_a.map do |character|
      RosterCharacterPresenter.new(character, removed: removed_user_ids.include?(character.user_id))
    end
  end

  # Archived characters visible to the viewer but hidden from the roster —
  # surfaced only as a count ("N inactive characters hidden").
  sig { returns(Integer) }
  def inactive_character_count
    game.characters.archived.visible_to(viewer, game).count
  end

  # Banned members, GM-only — empty for a non-manager so the section never
  # renders for a player. One presenter per row.
  sig { returns(T::Array[BannedMemberPresenter]) }
  def banned_members
    return [] unless can_manage?

    game.game_members.where(status: "banned").includes(:user).to_a.map { |m| BannedMemberPresenter.new(m) }
  end

  # The game's uploaded files, newest first — the Files tab's gallery.
  sig { returns(T::Array[GameFile]) }
  def game_files
    game.game_files.includes(file_attachment: :blob).order(created_at: :desc).to_a
  end

  # A blank file record for the Files tab's upload form.
  sig { returns(GameFile) }
  def new_game_file
    game.game_files.new
  end

  private

  sig { returns(Game) }
  def game
    @model.model
  end

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end

  sig { returns(T::Array[Scene]) }
  def raw_active_scenes
    @raw_active_scenes ||= T.let(
      game.scenes
        .visible_to(viewer, game)
        .active
        .includes(:parent_scene, :child_scenes, :posts, scene_participants: [ :character, :user ])
        .to_a
        .sort_by { |s| -s.last_activity_at.to_i },
      T.nilable(T::Array[Scene])
    )
  end

  # Scenes with activity since the viewer last logged in — the source hot
  # scene ids behind ScenePresenter#hot? for #active_scenes.
  sig { returns(T::Set[Integer]) }
  def hot_scene_ids
    last_login = viewer.user_profile&.last_login_at
    return Set.new unless last_login

    Set.new(raw_active_scenes.select { |s| s.last_activity_at.to_i > last_login.to_i }.map(&:id))
  end
end
