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
# not carry an affordance that belongs to a single viewer. PostItemComponent is
# rendered with suppress_edit so the author's "Edit" link never streams to other
# viewers; unread state needs no such care (the appended node carries none, and
# each client's unread-aura controller reconciles reads on its own). OOC hiding is
# client-side, so the streamed node carries data-ooc and each viewer's ooc-filter
# controller hides it.
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
  # append the rendered post to the list.
  sig { void }
  def created
    stream = [ scene, :posts ]
    Turbo::StreamsChannel.broadcast_remove_to(*stream, target: EMPTY_STATE_TARGET)
    Turbo::StreamsChannel.broadcast_append_to(*stream, target: POSTS_TARGET, renderable: component, layout: false)
  end

  # An edited post: replace it in place by its dom id.
  sig { void }
  def updated
    stream = [ scene, :posts ]
    Turbo::StreamsChannel.broadcast_replace_to(
      *stream, target: ActionView::RecordIdentifier.dom_id(@post), renderable: component, layout: false
    )
  end

  private

  sig { returns(Shared::PostItemComponent) }
  def component
    Shared::PostItemComponent.new(post: presenter, scene: scene_presenter, suppress_edit: true)
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
