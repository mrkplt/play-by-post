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

  sig { returns(User) }
  def user
    @model.user # mutant:disable
  end

  sig { returns(Scene) }
  def scene
    @model.scene # mutant:disable
  end

  private

  sig { returns(T::Array[SceneParticipant]) }
  def scene_participants
    @options.fetch(:scene_participants, [])
  end
end
