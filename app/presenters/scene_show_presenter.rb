# typed: strict

# View model for the scene screen (ScenesController#show): the viewer-scoped
# facts and collections that only that one screen needs — participation,
# mute state, the OOC filter, child scenes, the post list, and the footer
# page-action. Split out from ScenePresenter (used by cards, trees and other
# controllers that never supply a viewer) so that presenter stays small; this
# one wraps a ScenePresenter — a presenter subject is a legal BasePresenter
# subject alongside a model — plus the viewer and this screen's collaborators.
class SceneShowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(ScenePresenter) }
  def scene_presenter
    @model
  end

  # The scene screen's footer page-action, resolved to a render-ready
  # label/href/method triple; ScenePageAction owns the rule and the shape.
  # `can_manage` is the one viewer fact this presenter is not constructed
  # with (it is GamePresenter's capability, asked of the injected GamePolicy),
  # so it is the only remaining parameter; participation and membership are
  # this presenter's own to derive.
  sig { params(can_manage: T::Boolean).returns(T.nilable(ScenePageAction::Resolved)) }
  def page_action(can_manage:)
    ScenePageAction.resolved_for(
      scene: scene,
      viewer: ScenePageAction::Viewer.new(
        can_manage: can_manage, is_participant: participant?, membership: viewer_membership
      ),
      route_args: ScenePageAction::RouteArgs.new(urls: @options[:urls], game: @options[:game])
    )
  end

  # Whether the viewer participates in this scene — the scene-screen footer
  # action's viewer fact.
  sig { returns(T::Boolean) }
  def participant?
    scene.participant?(viewer)
  end

  # The viewer's membership in this scene's game, or nil — the other viewer
  # fact ScenePageAction needs.
  sig { returns(T.nilable(GameMember)) }
  def viewer_membership
    @options.fetch(:game).member_for(viewer)
  end

  # Whether the viewer has muted notifications for this scene.
  sig { returns(T::Boolean) }
  def muted?
    NotificationPreference.muted?(scene, viewer)
  end

  # Whether the viewer's OOC-post filter is on, from their profile — off by
  # default when there is no profile yet.
  sig { returns(T::Boolean) }
  def hide_ooc?
    viewer.user_profile&.hide_ooc? || false
  end

  # Child scenes visible to the viewer, oldest first — the scene screen's
  # thread-continuation list. Named distinctly from the delegated
  # Scene#child_scenes (an unfiltered association other callers, e.g.
  # Shared::SceneCardComponent, still read through ScenePresenter's
  # SimpleDelegator) so this viewer-scoped version does not shadow it.
  sig { returns(T::Array[Scene]) }
  def visible_child_scenes
    scene.child_scenes.visible_to(viewer, @options.fetch(:game)).order(:created_at).to_a
  end

  # Ids of this scene's posts the viewer has already read — the unread-aura
  # data Shared::PostItemComponent needs per post.
  sig { returns(T::Set[Integer]) }
  def read_post_ids
    SceneReadState.for(scene: scene, posts: published_posts, user: viewer)
  end

  # Published posts, oldest first, each wrapped for display — the scene
  # screen's post list.
  sig { returns(T::Array[PostPresenter]) }
  def post_presenters
    participants = scene.scene_participants.includes(:character, :user).to_a
    published_posts.map { |post| PostPresenter.new(post, scene_participants: participants) }
  end

  sig { returns(T::Boolean) }
  def posts_empty?
    published_posts.empty?
  end

  # The viewer's own draft in this scene, if any — for the composer and the
  # draft-recovery notice.
  sig { returns(T.nilable(Post)) }
  def draft
    scene.posts.drafts.find_by(user: viewer)
  end

  # A blank post for the composer form.
  sig { returns(Post) }
  def new_post
    Post.new
  end

  # Marks the viewer's participation as visited now — called once per #show,
  # not idempotent by design (it is the "last seen" timestamp).
  sig { void }
  def mark_visited!
    scene.scene_participants.find_by(user: viewer)&.update(last_visited_at: Time.current)
  end

  private

  sig { returns(Scene) }
  def scene
    @model.model
  end

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end

  sig { returns(T::Array[Post]) }
  def published_posts
    @published_posts ||= T.let(
      scene.posts.published.includes(:user).order(:created_at).to_a,
      T.nilable(T::Array[Post])
    )
  end
end
