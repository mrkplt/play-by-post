# typed: strict

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Scene, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The wrapped Scene, for the rare place that legitimately needs the raw
  # model: ScenePageAction's sig requires one, and SceneShowPresenter wraps a
  # ScenePresenter rather than a Scene. Everything else goes through a named
  # presenter method instead.
  sig { returns(Scene) }
  def model
    @model
  end

  # Whether this scene has activity since the viewer last logged in — the
  # dashboard/game-view card's attention glow. `hot_scene_ids` is supplied at
  # construction (options[:hot_scene_ids], defaulting to none) rather than
  # computed here, since "last login" is a viewer fact the presenter is not
  # constructed with by every caller.
  sig { returns(T::Boolean) }
  def hot?
    @options.fetch(:hot_scene_ids, Set.new).include?(@model.id)
  end

  sig { returns(String) }
  def title
    @model.title
  end

  # This scene's child scenes that belong to the given game, wrapped for
  # display — the scene card's "continued in" links show only same-game
  # children. Takes the game explicitly rather than reading @options[:game]
  # so callers that never call #page_action are not forced to construct with
  # a game they do not otherwise need.
  sig { params(game: GamePresenter).returns(T::Array[ScenePresenter]) }
  def child_scenes_in(game)
    @model.child_scenes.select { |c| c.game_id == game.id }.map { |c| ScenePresenter.new(c) }
  end

  sig { returns(T::Boolean) }
  def parent_scene?
    @model.parent_scene.present?
  end

  sig { returns(ScenePresenter) }
  def parent_scene_presenter
    ScenePresenter.new(@model.parent_scene)
  end

  sig { returns(String) }
  def parent_option_label
    @model.resolved? ? "#{@model.title} (Resolved)" : @model.title
  end

  # Whether the scene currently carries validation errors — the New Scene /
  # Quick Scene form's re-render after a failed #create reads this instead of
  # a component reaching into @model.errors directly.
  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  sig { returns(String) }
  def status_label
    @model.resolved? ? "Resolved" : "Active"
  end

  sig { returns(T::Boolean) }
  def resolved?
    @model.resolved? # mutant:disable
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene screen's meta row: Private and Resolved, each shown only when
  # true (no badge at all for an ordinary public, active scene).
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def status_badges
    badges = T.let([], T::Array[Shared::StatusBadgeRowComponent::Badge])
    badges << { label: "Private", variant: :yellow } if @model.private?
    badges << { label: "Resolved", variant: :gray } if @model.resolved?
    badges
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene tree row: always a status badge (Active/Resolved), plus Private
  # when set. The presenter picks the symbolic Ui::BadgeComponent variant so
  # the component never inspects the model directly.
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def tree_status_badges
    badges = T.let(
      [ { label: status_label, variant: @model.resolved? ? :gray : :green } ],
      T::Array[Shared::StatusBadgeRowComponent::Badge]
    )
    badges << { label: "Private", variant: :yellow } if @model.private?
    badges
  end

  sig { returns(String) }
  def participant_names
    @model.scene_participants
      .includes(:character, :user)
      .map(&:display_name)
      .join(", ")
  end

  # "N participants" — the only meta a scene card shows in the redesign.
  sig { returns(String) }
  def participant_summary
    count = @model.scene_participants.count
    "#{count} #{count == 1 ? 'participant' : 'participants'}"
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %l:%M%P")
  end

  sig { returns(String) }
  def tree_row_css_class
    @model.resolved? ? "text-slate-500" : "font-semibold"
  end

  sig { returns(String) }
  def tree_link_css_class
    @model.resolved? ? "text-slate-500" : ""
  end

  sig { returns(ActiveStorage::VariantWithRecord) }
  def banner_image
    @model.image.variant(resize_to_limit: [ 1200, nil ], format: :jpeg, quality: 85)
  end

  # The GM-facing resolution text shown once a scene is resolved. Named for
  # what it shows rather than delegated to raw `resolution`, so the presenter
  # (not the component) owns reading it off the model.
  sig { returns(T.nilable(String)) }
  def resolution
    @model.resolution
  end

  # The "End Scene" form's submit target, resolved from the game and
  # url_helpers supplied at construction (options[:game] / options[:urls]) so
  # the component never builds a route itself.
  sig { returns(String) }
  def resolve_path
    @options.fetch(:urls).resolve_game_scene_path(@options.fetch(:game), @model)
  end

  # Whether this viewer may post into the scene right now: the post policy allows
  # it and the scene is still open. Keeps the composer's visibility sourced from
  # the same policy PostsController authorizes with. The policy is supplied at
  # construction (options[:post_policy]) instead of built here, so the
  # presenter never constructs authorization itself.
  sig { returns(T::Boolean) }
  def can_post?
    @options.fetch(:post_policy).create? && !@model.resolved?
  end

  # The mute/unmute control's label, derived from the viewer's current
  # notification-preference state.
  sig { params(muted: T::Boolean).returns(String) }
  def mute_toggle_label(muted)
    muted ? "Unmute notifications" : "Mute notifications"
  end

  # The draft worth surfacing as a recovery notice for
  # Shared::DraftRecoveryComponent: the composer disappears once a scene
  # resolves, so a leftover draft is only worth recovering in that state.
  # `draft` is whatever #draft found (or nil), already wrapped.
  sig { params(draft: T.nilable(PostPresenter)).returns(T.nilable(PostPresenter)) }
  def recoverable_draft(draft)
    @model.resolved? ? draft : nil
  end

  # The scene screen's footer page-action, resolved to a render-ready
  # label/href/method triple; ScenePageAction owns the rule and the shape.
  # The game and url_helpers come from construction, so the view reads a
  # finished href rather than handing the presenter a route helper.
  # `can_manage` is the one viewer fact this presenter is not constructed
  # with (it is GamePresenter's capability, asked of the injected GamePolicy),
  # so it is the only remaining parameter; participation and membership are
  # this presenter's own to derive.
  sig { params(can_manage: T::Boolean).returns(T.nilable(ScenePageAction::Resolved)) }
  def page_action(can_manage:)
    ScenePageAction.resolved_for(
      scene: @model,
      viewer: ScenePageAction::Viewer.new(
        can_manage: can_manage, is_participant: participant?, membership: viewer_membership
      ),
      route_args: ScenePageAction::RouteArgs.new(
        urls: @options[:urls], game: @options[:game]
      )
    )
  end

  # The composer's autosave-draft endpoint, resolved here so the composer
  # component never holds the game/scene models it would need to build the
  # URL itself. `urls`/`game` are supplied at construction (options[:urls],
  # options[:game]) — the same collaborators #page_action reads.
  sig { returns(String) }
  def save_draft_url
    url_helpers.save_draft_game_scene_posts_path(scene_game, @model) # mutant:disable
  end

  # The "discard this draft" endpoint, resolved the same way as save_draft_url.
  sig { returns(String) }
  def discard_draft_url
    url_helpers.discard_draft_game_scene_posts_path(scene_game, @model) # mutant:disable
  end

  # Whether the viewer participates in this scene — the scene-screen footer
  # action's viewer fact. `current_user` is supplied at construction
  # (options[:current_user]).
  sig { returns(T::Boolean) }
  def participant?
    @model.participant?(viewer)
  end

  # The viewer's membership in this scene's game, or nil — the other viewer
  # fact ScenePageAction needs.
  sig { returns(T.nilable(GameMember)) }
  def viewer_membership
    scene_game.member_for(viewer)
  end

  # Whether the viewer has muted notifications for this scene.
  sig { returns(T::Boolean) }
  def muted?
    NotificationPreference.muted?(@model, viewer)
  end

  # Whether the viewer's OOC-post filter is on, from their profile — off by
  # default when there is no profile yet.
  sig { returns(T::Boolean) }
  def hide_ooc?
    viewer.user_profile&.hide_ooc? || false
  end

  # Child scenes visible to the viewer, oldest first, wrapped for
  # Shared::ChildSceneListComponent — the scene screen's thread-continuation
  # list. Named distinctly from #child_scenes_in (which filters by game only,
  # for the card use case) because this one is additionally scoped to what
  # the viewer may see.
  sig { returns(T::Array[ScenePresenter]) }
  def visible_child_scenes
    @model.child_scenes.visible_to(viewer, scene_game).order(:created_at).to_a.map { |s| ScenePresenter.new(s) }
  end

  # Ids of this scene's posts the viewer has already read — the unread-aura
  # data Shared::PostItemComponent needs per post.
  sig { returns(T::Set[Integer]) }
  def read_post_ids
    SceneReadState.for(scene: @model, posts: published_posts, user: viewer)
  end

  # Published posts, oldest first, each wrapped for display — the scene
  # screen's post list. Built and supplied by the controller
  # (options[:post_presenters]) rather than built here: each post needs its
  # own PostPolicy, and presenters never construct authorization (R2) — only
  # the controller has Pundit's policy(post) to hand over already resolved.
  sig { returns(T::Array[PostPresenter]) }
  def post_presenters
    @options.fetch(:post_presenters, [])
  end

  sig { returns(T::Boolean) }
  def posts_empty?
    post_presenters.empty?
  end

  # The viewer's own draft in this scene, if any, wrapped for the composer
  # and the draft-recovery notice.
  sig { returns(T.nilable(PostPresenter)) }
  def draft
    found = @model.posts.drafts.find_by(user: viewer)
    return nil unless found

    PostPresenter.new(found)
  end

  # A blank post for the composer form, wrapped the same way.
  sig { returns(PostPresenter) }
  def new_post
    PostPresenter.new(Post.new)
  end

  # Marks the viewer's participation as visited now — called once per #show,
  # not idempotent by design (it is the "last seen" timestamp).
  sig { void }
  def mark_visited!
    @model.scene_participants.find_by(user: viewer)&.update(last_visited_at: Time.current)
  end

  private

  sig { returns(T.untyped) }
  def url_helpers
    @options.fetch(:urls)
  end

  sig { returns(Game) }
  def scene_game
    @options.fetch(:game)
  end

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end

  sig { returns(T::Array[Post]) }
  def published_posts
    @published_posts ||= T.let(
      @model.posts.published.includes(:user).order(:created_at).to_a,
      T.nilable(T::Array[Post])
    )
  end
end
