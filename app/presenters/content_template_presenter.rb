# typed: strict

# View model for a content template across its management screens: the index
# row, and the new/edit form. Collaborators (the game and url_helpers) are
# supplied at construction so route resolution lives here, not in the templates.
class ContentTemplatePresenter < BasePresenter
  extend T::Sig

  sig { params(model: ContentTemplate, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def content_type
    @model.content_type.to_s
  end

  # The human label for the content type — the model stores the lowercase key.
  sig { returns(String) }
  def content_type_label
    content_type.capitalize
  end

  sig { returns(String) }
  def body
    @model.body.to_s
  end

  sig { returns(T::Boolean) }
  def new_record?
    @model.new_record?
  end

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # The content types still available to create a template for — the form's
  # select offers only types this game does not already have.
  sig { returns(T::Array[String]) }
  def available_content_types
    taken = @model.game.content_templates.where.not(id: @model.id).pluck(:content_type)
    ContentTemplate::CONTENT_TYPES - taken
  end

  # This template's own title/href pair for a Shared::ListEntryComponent row —
  # the values the templates list needs about the template, packaged here so the
  # list does not reach into the presenter for each.
  sig { returns({ title: String, href: String }) }
  def list_row_attributes
    { title: content_type_label, href: edit_path }
  end

  sig { returns(String) }
  def edit_path
    @options.fetch(:urls).edit_game_content_template_path(@options.fetch(:game), @model)
  end

  sig { returns(String) }
  def delete_path
    @options.fetch(:urls).game_content_template_path(@options.fetch(:game), @model)
  end
end
