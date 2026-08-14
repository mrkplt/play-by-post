# typed: strict

# View model for the scene notification emails (new scene, scene resolved,
# post digest). Wraps a ScenePresenter — composition, not duplication.
#
# Mailers are controllers and their templates are views, so the same rule
# applies: the template reads finished values, never the model. They differ
# from a controller in one way only — there is no viewer and no Pundit, so
# nothing here is a capability question and no policy is injected.
#
# `nil` rather than blank-string for the optional prose, so the template's
# presence gate is `<% if (text = presenter.description) %>` with no predicate
# of its own.
class SceneNotificationPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def title
    @model.title
  end

  # The scene's opening prose, or nil when it has none.
  sig { returns(T.nilable(String)) }
  def description
    scene.description.presence
  end

  # The GM's closing text once the scene is resolved, or nil.
  sig { returns(T.nilable(String)) }
  def resolution
    @model.resolution
  end

  # The scene's own URL — the email's primary link.
  sig { returns(String) }
  def scene_url
    @options.fetch(:scene_url)
  end

  # The unsubscribe/mute link, present on the emails that offer one.
  sig { returns(String) }
  def mute_url
    @options.fetch(:mute_url)
  end

  # The digest's posts, already wrapped. Empty for the other notifications.
  sig { returns(T::Array[PostPresenter]) }
  def post_presenters
    @options.fetch(:post_presenters, [])
  end

  # How many further posts the digest omitted, for its "and N more" line.
  sig { returns(Integer) }
  def extra_count
    @options.fetch(:extra_count, 0)
  end

  private

  sig { returns(Scene) }
  def scene
    T.cast(@model.__getobj__, Scene)
  end
end
