# typed: strict

class PostPresenter < BasePresenter
  extend T::Sig
  include Draftable::Presentation

  sig { params(model: Post, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def author_display_name
    user = @model.user
    author_participant&.display_name || user.display_name || user.email
  end

  # The byline avatar: a post in a scene speaks as a character, so this is the
  # character's portrait — nil (monogram fallback) for a GM post, whose
  # participant has no character. Built via the injected urls, not a view route.
  sig { returns(T.nilable(String)) }
  def author_avatar_url
    variant = author_participant&.character&.portrait_variant
    variant && @options.fetch(:urls).url_for(variant)
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %-I:%M %p")
  end

  sig { returns(ActiveSupport::TimeWithZone) }
  def created_at
    @model.created_at # mutant:disable
  end

  sig { returns(Integer) }
  def id
    @model.id # mutant:disable
  end

  sig { returns(T::Boolean) }
  def is_ooc?
    @model.is_ooc? # mutant:disable
  end

  sig { returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def last_edited_at
    @model.last_edited_at # mutant:disable
  end

  # Whether the viewer may still edit this post — the post's 10-minute edit
  # window plus authorship, via the injected PostPolicy (options[:policy]) so
  # the presenter never constructs authorization itself.
  sig { returns(T::Boolean) }
  def editable_by_viewer?
    @options.fetch(:policy).update? # mutant:disable
  end

  sig { returns(String) }
  def content
    @model.content.to_s # mutant:disable
  end

  # Whether this post's author is the game's GM — the post item's avatar-tone
  # decision. The game is supplied at construction (options[:game]).
  sig { returns(T::Boolean) }
  def author_is_gm?
    @options.fetch(:game).game_master?(@model.user) # mutant:disable
  end

  # A presenter for this post's "mark read" / edit URLs, built from the same
  # game/scene/urls this presenter was constructed with — split out to keep
  # this class under the project's method ceiling.
  sig { returns(PostRoutesPresenter) }
  def routes
    PostRoutesPresenter.new(@model, game: @options.fetch(:game), scene: @options.fetch(:scene, @model.scene), urls: @options.fetch(:urls))
  end

  private

  # This post's author as a scene participant (their character in this scene),
  # or nil when the author isn't a participant. Both the byline name and the
  # byline avatar ask for it; the participant list is a small in-memory array
  # already loaded for the scene, so re-finding per caller is cheaper than a
  # memo ivar. Returns T.untyped rather than T.nilable(SceneParticipant): the
  # callers only reach through it with `&.`, and a nilable-model runtime sig
  # would reject the verifying doubles the builder/post specs pass here.
  sig { returns(T.untyped) }
  def author_participant
    scene_participants.find { |sp| sp.user_id == @model.user_id }
  end

  sig { returns(T::Array[SceneParticipant]) }
  def scene_participants
    @options.fetch(:scene_participants, [])
  end
end
