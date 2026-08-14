# typed: strict

# View model for a game and its viewer. Replaces the derived boolean the
# controllers used to thread into views: the capability check is a method here,
# backed by the policy so an affordance can never diverge from what the
# controller authorizes.
class GamePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The viewer may administer this game. A capability, not a role: it asks the
  # policy's `manage?` rather than `update?` (which means "this row may be
  # modified") so the view layer never hard-codes who currently qualifies.
  # The policy is supplied at construction (options[:policy]) rather than
  # built here, so a capability rename is chased through one call site
  # instead of every presenter that asks the question.
  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:policy).manage?
  end

  # The viewer's display name — trivial delegation, but explicit so a
  # component's template calling it on this presenter is Sorbet-checkable
  # (SimpleDelegator passthrough is invisible to static analysis).
  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(T.nilable(String)) }
  def description
    @model.description
  end

  sig { returns(Integer) }
  def id
    @model.id
  end

  sig { returns(T::Boolean) }
  def ai_summaries_enabled?
    @model.ai_summaries_enabled?
  end

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # Outstanding (unaccepted) invitations for this game, newest first — the data
  # behind the GM-only invite panel on the Roster tab. Each is paired with
  # this game and the constructing controller's route helpers so the
  # component never builds an invitation route of its own.
  sig { returns(T::Array[InvitationPresenter]) }
  def pending_invitations
    @model.invitations.pending.order(created_at: :desc).to_a.map do |invitation|
      InvitationPresenter.new(invitation, game: @model, urls: @options.fetch(:urls))
    end
  end

  # The game's pages, alphabetised by title — the data behind the Pages tab.
  sig { returns(T::Array[PagePresenter]) }
  def pages
    @model.pages.order(:title).to_a.map do |page|
      PagePresenter.new(page, game: @model, urls: @options.fetch(:urls))
    end
  end

  # The game's links, newest first — the data behind the Links tab.
  sig { returns(T::Array[GameLinkPresenter]) }
  def links
    @model.game_links.order(created_at: :desc).to_a.map do |game_link|
      GameLinkPresenter.new(game_link, game: @model, urls: @options.fetch(:urls))
    end
  end

  # The game's Campaign Notebook board — the data behind the GM-only Notebook
  # tab. NotebookBoardPresenter owns the grouping-by-lane query, so this is a
  # presenter wrapping a presenter, not a hash of models handed to the view.
  sig { returns(NotebookBoardPresenter) }
  def notebook_board
    NotebookBoardPresenter.new(@model)
  end

  # Whether image attachments are turned off for this game — the post
  # composer's decision on whether to show its image field.
  sig { returns(T::Boolean) }
  def images_disabled?
    @model.images_disabled? # mutant:disable
  end

  # The game's active scenes visible to the viewer, most recently active
  # first — the Scenes panel's card list. Each scene is aware of whether it
  # counts as "hot" (activity since the viewer's last login), via
  # ScenePresenter#hot? reading the same hot_scene_ids this presenter derives.
  # `current_user` is supplied at construction (options[:current_user]).
  sig { returns(T::Array[ScenePresenter]) }
  def active_scenes
    hot_ids = hot_scene_ids
    raw_active_scenes.map { |s| ScenePresenter.new(s, hot_scene_ids: hot_ids) }
  end

  # The GM's display name — always shown, crowned, at the top of the "In
  # Active Scenes" roster preview.
  sig { returns(String) }
  def gm_name
    gm = @model.game_members.game_masters.includes(:user).first&.user
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
    removed_user_ids = @model.game_members.where(status: "removed").pluck(:user_id).to_set

    @model.characters.active.visible_to(viewer, @model).includes(:user).order(:name).to_a.map do |character|
      RosterCharacterPresenter.new(character, removed: removed_user_ids.include?(character.user_id))
    end
  end

  # Archived characters visible to the viewer but hidden from the roster —
  # surfaced only as a count ("N inactive characters hidden").
  sig { returns(Integer) }
  def inactive_character_count
    @model.characters.archived.visible_to(viewer, @model).count
  end

  # Banned members, GM-only — empty for a non-manager so the section never
  # renders for a player. One presenter per row.
  sig { returns(T::Array[BannedMemberPresenter]) }
  def banned_members
    return [] unless can_manage?

    @model.game_members.where(status: "banned").includes(:user).to_a.map { |m| BannedMemberPresenter.new(m) }
  end

  # The game's uploaded files, newest first, wrapped for
  # Shared::GalleryComponent — each carries its own download/delete URLs and
  # thumbnail markup, resolved from the game/helpers/can_manage supplied here
  # at construction (options[:helpers]) rather than the component reaching
  # for a route or view helper of its own.
  sig { returns(T::Array[GameFilePresenter]) }
  def game_files
    @model.game_files.includes(file_attachment: :blob).order(created_at: :desc).to_a.map do |gf|
      GameFilePresenter.new(gf, game: @model, helpers: @options.fetch(:helpers), can_manage: can_manage?)
    end
  end

  # A blank file record for the Files tab's upload form, wrapped the same way.
  sig { returns(GameFilePresenter) }
  def new_game_file
    GameFilePresenter.new(@model.game_files.new, game: @model, helpers: @options.fetch(:helpers), can_manage: can_manage?)
  end

  private

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end

  sig { returns(T::Array[Scene]) }
  def raw_active_scenes
    @raw_active_scenes ||= T.let(
      @model.scenes
        .visible_to(viewer, @model)
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
