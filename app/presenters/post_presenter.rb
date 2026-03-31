# typed: true

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
end
