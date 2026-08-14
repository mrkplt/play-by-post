# typed: strict

# View model for ScenesController#show's viewer-scoped chrome: participation,
# mute state, the OOC filter, and the footer page-action. Post-list/composer
# concerns live on the sibling ScenePostsPresenter, split out purely to keep
# each presenter under the project's file-length ceiling. Wraps a
# ScenePresenter — composition, not duplication — per the layering rule that
# a presenter's subject may be a model or another presenter.
class SceneShowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The mute/unmute control's label, derived from the viewer's current
  # notification-preference state.
  sig { params(muted: T::Boolean).returns(String) }
  def mute_toggle_label(muted)
    muted ? "Unmute notifications" : "Mute notifications"
  end

  # Whether the viewer has muted notifications for this scene.
  sig { returns(T::Boolean) }
  def muted?
    NotificationPreference.muted?(@model.model, viewer)
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
      scene: @model.model,
      viewer: ScenePageAction::Viewer.new(
        can_manage: can_manage, is_participant: participant?, membership: viewer_membership
      ),
      route_args: ScenePageAction::RouteArgs.new(
        urls: @options[:urls], game: @options[:game]
      )
    )
  end

  # Whether the viewer participates in this scene — the scene-screen footer
  # action's viewer fact. `current_user` is supplied at construction
  # (options[:current_user]).
  sig { returns(T::Boolean) }
  def participant?
    @model.model.participant?(viewer)
  end

  # The viewer's membership in this scene's game, or nil — the other viewer
  # fact ScenePageAction needs.
  sig { returns(T.nilable(GameMember)) }
  def viewer_membership
    show_game.member_for(viewer)
  end

  # Whether the viewer's OOC-post filter is on, from their profile — off by
  # default when there is no profile yet.
  sig { returns(T::Boolean) }
  def hide_ooc?
    viewer.user_profile&.hide_ooc? || false
  end

  # Child scenes visible to the viewer, oldest first, wrapped for
  # Shared::ChildSceneListComponent — the scene screen's thread-continuation
  # list.
  sig { returns(T::Array[ScenePresenter]) }
  def visible_child_scenes
    @model.model.child_scenes.visible_to(viewer, show_game).order(:created_at).to_a.map { |s| ScenePresenter.new(s) }
  end

  private

  sig { returns(Game) }
  def show_game
    @options.fetch(:game)
  end

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end
end
