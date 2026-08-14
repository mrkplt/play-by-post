# typed: strict

class PostPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Post, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def author_display_name
    participant = scene_participants.find { |sp| sp.user_id == @model.user_id }
    participant&.display_name || @model.user.display_name || @model.user.email
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

  sig { returns(T.untyped) }
  def image
    @model.image # mutant:disable
  end

  sig { returns(T.untyped) }
  def display_image
    @model.display_image # mutant:disable
  end

  sig { returns(T::Boolean) }
  def image_attached?
    @model.image.attached? # mutant:disable
  end

  sig { returns(User) }
  def user
    @model.user # mutant:disable
  end

  sig { returns(Scene) }
  def scene
    @model.scene # mutant:disable
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

  # The "mark read" / edit endpoints for this post, resolved here so the
  # component never holds the game/scene models to build a URL of its own.
  # `urls`/`game`/`scene` are supplied at construction.
  sig { returns(String) }
  def mark_read_url
    url_helpers.mark_read_game_scene_post_path(post_game, post_scene, @model) # mutant:disable
  end

  sig { returns(String) }
  def edit_url
    url_helpers.edit_game_scene_post_path(post_game, post_scene, @model) # mutant:disable
  end

  private

  sig { returns(T::Array[SceneParticipant]) }
  def scene_participants
    @options.fetch(:scene_participants, [])
  end

  sig { returns(T.untyped) }
  def url_helpers
    @options.fetch(:urls)
  end

  sig { returns(Game) }
  def post_game
    @options.fetch(:game)
  end

  sig { returns(Scene) }
  def post_scene
    @options.fetch(:scene, @model.scene)
  end
end
