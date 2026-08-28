# typed: true
# frozen_string_literal: true

# Pushes a created or edited post to every viewer on the scene page.
#
# The scene page subscribes each viewer to the single `[scene, :posts]` stream
# (PostsChannel authorizes it). PostsController#create/#update call this after the
# write so the post appears/updates live for everyone, not just the submitter who
# already got the direct HTTP turbo_stream response.
#
# The render is VIEWER-NEUTRAL: one message reaches every subscriber, so it must
# not carry an affordance that belongs to a single viewer. Three per-viewer
# concerns are handled client-side so one render serves everyone:
#   - Edit link: rendered with suppress_edit, so it never streams to other
#     viewers; the author's own Edit link is revealed by post-edit-affordance.
#   - Unread glow: a created post renders force_unread (glow + mark-read
#     affordance) since it is new to whoever is watching; the unread-aura
#     controller un-glows it for the author (its own author). An edited post is
#     not force_unread — an edit is not new activity.
#   - OOC hiding: the node carries data-ooc and each viewer's ooc-filter
#     controller hides it.
class PostBroadcast
  extend T::Sig

  # The list container the created post appends into, and the empty-state element
  # a first post removes — both fixed ids owned by Shared::UnreadAuraComponent.
  POSTS_TARGET = "posts"
  EMPTY_STATE_TARGET = "no_posts_message"

  sig { params(post: Post).void }
  def initialize(post)
    @post = post
  end

  # A newly created post: clear the empty state (harmless if already gone) and
  # append the rendered post to the list. Rendered force_unread so it arrives with
  # the glow + mark-read affordance; the unread-aura controller un-glows it for
  # the author client-side.
  sig { void }
  def created
    stream = [ scene, :posts ]
    Turbo::StreamsChannel.broadcast_remove_to(*stream, target: EMPTY_STATE_TARGET)
    Turbo::StreamsChannel.broadcast_append_to(*stream, target: POSTS_TARGET, renderable: component(force_unread: true), layout: false)
  end

  # An edited post: replace it in place by its dom id. Not force_unread — an edit
  # is not new activity, so it must not re-glow for everyone.
  sig { void }
  def updated
    stream = [ scene, :posts ]
    Turbo::StreamsChannel.broadcast_replace_to(
      *stream, target: ActionView::RecordIdentifier.dom_id(@post), renderable: component(force_unread: false), layout: false
    )
  end

  private

  sig { params(force_unread: T::Boolean).returns(Shared::PostItemComponent) }
  def component(force_unread:)
    Shared::PostItemComponent.new(
      post: presenter, scene: scene_presenter,
      presentation: Shared::PostItemComponent.broadcast(force_unread: force_unread)
    )
  end

  # A broadcast presenter: game/scene/urls from application routes (no request),
  # scene participants loaded so the byline can name the speaker. No policy is
  # supplied — suppress_edit means the component never asks editable_by_viewer?,
  # the only reader of it.
  sig { returns(PostPresenter) }
  def presenter
    PostPresenter.new(
      @post,
      scene_participants: scene.scene_participants.includes(:character, :user).to_a,
      game: T.must(scene.game),
      scene: scene,
      urls: Rails.application.routes.url_helpers
    )
  end

  sig { returns(ScenePresenter) }
  def scene_presenter
    ScenePresenter.new(scene, game: T.must(scene.game), urls: Rails.application.routes.url_helpers)
  end

  sig { returns(Scene) }
  def scene
    T.must(@post.scene)
  end
end
