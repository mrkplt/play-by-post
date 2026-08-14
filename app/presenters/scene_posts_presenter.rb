# typed: strict

# View model for ScenesController#show's post list and composer: the viewer's
# own draft, whether they may post right now, and the published posts
# themselves. Wraps a ScenePresenter — composition, not duplication — split
# out from SceneShowPresenter (which keeps the page-action/participation
# concerns) purely to keep each presenter under the project's file-length
# ceiling; both answer "what does this viewer see in this scene."
class ScenePostsPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
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

  # The draft worth surfacing as a recovery notice for
  # Shared::DraftRecoveryComponent: the composer disappears once a scene
  # resolves, so a leftover draft is only worth recovering in that state.
  # `draft` is whatever #draft found (or nil), already wrapped.
  sig { params(draft: T.nilable(PostPresenter)).returns(T.nilable(PostPresenter)) }
  def recoverable_draft(draft)
    @model.resolved? ? draft : nil
  end

  # Ids of this scene's posts the viewer has already read — the unread-aura
  # data Shared::PostItemComponent needs per post.
  # Memoized: the scene template passes this into every Shared::PostItemComponent
  # in the posts loop, so an unmemoized read runs SceneReadState.for once per
  # post (22 queries on a 20-post scene against 3 memoized). The controller
  # computed this once into an ivar before the layering sweep; memoizing keeps
  # that single-query behaviour now that it lives on the presenter.
  sig { returns(T::Set[Integer]) }
  def read_post_ids
    @read_post_ids ||= T.let(
      SceneReadState.for(scene: @model.model, posts: published_posts, user: viewer),
      T.nilable(T::Set[Integer])
    )
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
    found = @model.model.posts.drafts.find_by(user: viewer)
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
    @model.model.scene_participants.find_by(user: viewer)&.update(last_visited_at: Time.current)
  end

  private

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end

  sig { returns(T::Array[Post]) }
  def published_posts
    @published_posts ||= T.let(
      @model.model.posts.published.includes(:user).order(:created_at).to_a,
      T.nilable(T::Array[Post])
    )
  end
end
