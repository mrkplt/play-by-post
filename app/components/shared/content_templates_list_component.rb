# typed: strict

# The Content Templates management screen body: a New Template action (shown
# only while some content type is still untemplated) and the game's templates as
# a Shared::ListEntryComponent card — each row's title is the content type, its
# href edits the template, and its controls are Edit/Delete. GM-only; the
# controller gates access.
class Shared::ContentTemplatesListComponent < ApplicationComponent
  extend T::Sig

  INTRO = "New page, note, and character records start from these templates."
  EMPTY = "No templates yet."

  # Stable wrapper id so ContentTemplatesController re-renders the list in place
  # after a delete.
  DOM_ID = "content_templates_list"

  sig do
    params(
      game: GamePresenter,
      templates: T::Array[ContentTemplatePresenter]
    ).void
  end
  def initialize(game:, templates:)
    @game = T.let(game, GamePresenter)
    @templates = T.let(templates, T::Array[ContentTemplatePresenter])
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  # New templates can be added only while some content type has no template yet.
  sig { returns(T::Boolean) }
  def can_add?
    @templates.size < ContentTemplate::CONTENT_TYPES.size
  end

  # The templates as Shared::ListEntryComponent rows — the type label linking to
  # its edit screen, with Edit/Delete controls.
  sig { returns(T::Array[Shared::ListEntryComponent::Row]) }
  def rows
    @templates.map do |template|
      template.list_row_attributes.merge(controls: Shared::TemplateRowActionsComponent.new(template: template))
    end
  end
end
