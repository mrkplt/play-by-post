# typed: strict

class PostPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Post, scene_participants: T::Array[SceneParticipant]).void }
  def initialize(model, scene_participants: [])
    super(model)
    @scene_participants = scene_participants
  end

  sig { returns(String) }
  def author_display_name
    participant = @scene_participants.find { |sp| sp.user_id == @model.user_id }
    participant&.display_name || @model.user.display_name || @model.user.email
  end

  sig { returns(String) }
  def rendered_content
    MarkdownRenderer.render(@model.content)
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %-I:%M %p")
  end

  sig { returns(ActiveSupport::TimeWithZone) }
  def created_at
    @model.created_at
  end

  sig { returns(Integer) }
  def id
    @model.id
  end

  sig { returns(T::Boolean) }
  def is_ooc?
    @model.is_ooc?
  end

  sig { returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def last_edited_at
    @model.last_edited_at
  end

  sig { params(user: User).returns(T::Boolean) }
  def editable_by?(user)
    @model.editable_by?(user)
  end

  sig { returns(T.untyped) }
  def image
    @model.image
  end

  sig { returns(T.untyped) }
  def display_image
    @model.display_image
  end
end
