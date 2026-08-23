# typed: strict

# View model for GamesController#show's Scenes panel: the active-scene cards
# and the "In Active Scenes" roster preview above them. Wraps a GamePresenter
# — composition, not duplication. The Roster panel's character/banned rows
# live in GameRosterPresenter; the two were split along the boundary the
# template already draws between the two panels.
class GameScenesPanelPresenter < BasePresenter
  extend T::Sig

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])

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
  # "GM" when the game has no game master assigned yet.
  sig { returns(String) }
  def gm_name
    @gm_name ||= T.let(gm_user ? UserPresenter.new(gm_user).display_name_or_email : "GM", T.nilable(String))
  end

  # The GM's player avatar URL for the crowned preview row (nil → monogram) —
  # the GM row is a person, so it uses the player avatar, not a character.
  sig { returns(T.nilable(String)) }
  def gm_avatar_url
    variant = gm_user&.avatar_variant
    variant && @options.fetch(:helpers).url_for(variant)
  end

  # Up to five distinct characters participating in an active scene, each paired
  # with that scene's title and portrait URL. Banned players are already
  # excluded from scene participation.
  sig { returns(T::Array[T::Hash[Symbol, T.nilable(String)]]) }
  def roster_preview
    @roster_preview ||= T.let(
      raw_active_scenes
        .flat_map { |scene| SceneRosterRowsPresenter.new(ScenePresenter.new(scene), helpers: @options.fetch(:helpers)).rows }
        .uniq { |row| row[:name] }
        .first(5),
      T.nilable(T::Array[T::Hash[Symbol, T.nilable(String)]])
    )
  end

  sig { returns(T::Boolean) }
  def roster_preview_empty?
    roster_preview.empty?
  end

  # Whether the GM row is the only row in the preview — the crowned GM row's
  # position (no divider under it) when no players have joined an active
  # scene yet.
  sig { returns(Symbol) }
  def gm_row_position
    POSITIONS.fetch(roster_preview_empty?)
  end

  sig { params(index: Integer).returns(Symbol) }
  def roster_preview_position(index)
    POSITIONS.fetch(index == roster_preview.length - 1)
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

  sig { returns(T.nilable(User)) }
  def gm_user
    @gm_user ||= T.let(game.game_members.game_masters.includes(:user).first&.user, T.nilable(User))
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
