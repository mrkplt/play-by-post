# typed: strict

# View model for GamesController#show's Scenes panel: the active-scene cards
# and the "In Active Scenes" roster preview above them. Wraps a GamePresenter
# — composition, not duplication. The Roster panel's character/banned rows
# live in GameRosterPresenter; the two were split along the boundary the
# template already draws between the two panels.
class GameScenesPanelPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The game's active scenes visible to the viewer, most recently active
  # first. Each scene knows whether it counts as "hot" (activity since the
  # viewer's last login) via the shared hot_scene_ids derived here.
  sig { returns(T::Array[ScenePresenter]) }
  def active_scenes
    @active_scenes ||= T.let(build_active_scenes, T.nilable(T::Array[ScenePresenter]))
  end

  sig { returns(T::Boolean) }
  def active_scenes?
    active_scenes.any?
  end

  # The GM's display name — always shown, crowned, at the top of the preview.
  sig { returns(String) }
  def gm_name
    @gm_name ||= T.let(build_gm_name, T.nilable(String))
  end

  # Up to five distinct characters participating in an active scene, each
  # paired with that scene's title. Banned players are already excluded from
  # scene participation.
  sig { returns(T::Array[T::Hash[Symbol, String]]) }
  def roster_preview
    @roster_preview ||= T.let(build_roster_preview, T.nilable(T::Array[T::Hash[Symbol, String]]))
  end

  sig { returns(T::Boolean) }
  def roster_preview_empty?
    roster_preview.empty?
  end

  # Whether the GM row is the only row in the preview — the crowned GM row's
  # "last" flag (no divider under it) when no players have joined an active
  # scene yet.
  sig { returns(T::Boolean) }
  def gm_row_last?
    roster_preview_empty?
  end

  sig { params(index: Integer).returns(T::Boolean) }
  def roster_preview_last?(index)
    index == roster_preview.length - 1
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

  # Memoized: the template asks for these while laying out the panel, and each
  # is a query.
  sig { returns(T::Array[ScenePresenter]) }
  def build_active_scenes
    hot_ids = hot_scene_ids
    raw_active_scenes.map { |scene| ScenePresenter.new(scene, hot_scene_ids: hot_ids) }
  end

  sig { returns(String) }
  def build_gm_name
    gm = game.game_members.game_masters.includes(:user).first&.user
    gm ? UserPresenter.new(gm).display_name_or_email : "GM"
  end

  sig { returns(T::Array[T::Hash[Symbol, String]]) }
  def build_roster_preview
    rows = raw_active_scenes.flat_map { |scene| SceneRosterRowsPresenter.new(ScenePresenter.new(scene)).rows }
    rows.uniq { |row| row[:name] }.first(5)
  end

  sig { returns(T::Array[Scene]) }
  def raw_active_scenes
    @raw_active_scenes ||= T.let(
      game.scenes
        .visible_to(viewer, game)
        .active
        .includes(:parent_scene, :child_scenes, :posts, scene_participants: [ :character, :user ])
        .to_a
        .sort_by { |scene| -scene.last_activity_at.to_i },
      T.nilable(T::Array[Scene])
    )
  end

  sig { returns(T::Set[Integer]) }
  def hot_scene_ids
    last_login = viewer.user_profile&.last_login_at
    return Set.new unless last_login

    Set.new(raw_active_scenes.select { |scene| scene.last_activity_at.to_i > last_login.to_i }.map(&:id))
  end
end
