# typed: strict

class SceneSummaryPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def rendered_body
    MarkdownRenderer.render(@model.body)
  end

  sig { returns(String) }
  def status_label
    if @model.ai_generated? && @model.edited?
      "Edited"
    elsif @model.ai_generated?
      "AI-generated"
    else
      "Hand-written"
    end
  end

  sig { returns(T.nilable(String)) }
  def formatted_generated_at
    return nil unless @model.generated_at

    @model.generated_at.strftime("%b %-d, %Y")
  end

  sig { returns(T.nilable(String)) }
  def formatted_edited_at
    return nil unless @model.edited_at

    @model.edited_at.strftime("%b %-d, %Y")
  end

  sig { returns(T::Boolean) }
  def ai_generated?
    @model.ai_generated? # mutant:disable
  end

  sig { returns(T::Boolean) }
  def edited?
    @model.edited? # mutant:disable
  end

  sig { returns(Scene) }
  def scene
    @model.scene # mutant:disable
  end
end
