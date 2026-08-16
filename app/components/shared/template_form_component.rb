# typed: strict

# The New Template / Edit Template form: the content type this template seeds
# and its markdown body. On a new template the type is a select of the types the
# game does not already have; on edit the type is fixed. The component derives
# its mode, labels, and back-href from the presenter, so the view renders it
# with just the presenter.
class Shared::TemplateFormComponent < ApplicationComponent
  extend T::Sig
  include Shared::RecordBackedForm

  sig { params(game: GamePresenter, template: ContentTemplatePresenter).void }
  def initialize(game:, template:)
    @game = T.let(game, GamePresenter)
    @template = T.let(template, ContentTemplatePresenter)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(ContentTemplatePresenter) }
  attr_reader :template

  sig { override.returns(ContentTemplatePresenter) }
  def record
    template
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Template" : "Save"
  end

  sig { returns(T::Array[String]) }
  def content_type_options
    template.available_content_types
  end

  sig { returns(String) }
  def back_href
    helpers.game_content_templates_path(game)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "new_content_template_form" : "edit_content_template_form"
  end
end
