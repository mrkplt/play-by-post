# typed: strict

# The Content Templates management screen body: the game's per-type templates
# (one row each, with Edit and Delete) and a New Template action when types are
# still available. GM-only — the controller gates access; this component only
# lays the management surface out.
class Shared::ContentTemplatesListComponent < ApplicationComponent
  extend T::Sig

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

  sig { returns(T::Array[ContentTemplatePresenter]) }
  attr_reader :templates

  sig { returns(T::Boolean) }
  def any_templates?
    templates.any?
  end

  # New templates can be added only while some content type has no template yet.
  sig { returns(T::Boolean) }
  def can_add?
    templates.size < ContentTemplate::CONTENT_TYPES.size
  end
end
