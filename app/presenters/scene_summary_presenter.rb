# typed: strict

class SceneSummaryPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  # mutant:disable
  def rendered_body
    MarkdownRenderer.render(@model.body)
  end

  sig { returns(String) }
  # mutant:disable
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
  # mutant:disable
  def formatted_generated_at
    return nil unless @model.generated_at

    @model.generated_at.strftime("%b %-d, %Y")
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_edited_at
    return nil unless @model.edited_at

    @model.edited_at.strftime("%b %-d, %Y")
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def ai_generated?
    @model.ai_generated?
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def edited?
    @model.edited?
  end

  sig { returns(Scene) }
  # mutant:disable
  def scene
    @model.scene
  end
end
