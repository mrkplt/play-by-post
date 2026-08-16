# typed: strict

# The GM's per-row actions on the Templates list: edit the template or delete it
# behind a confirmation. Rendered as a Shared::ListEntryComponent row's controls,
# mirroring Shared::PageRowActionsComponent.
class Shared::TemplateRowActionsComponent < ApplicationComponent
  extend T::Sig

  CONFIRM = "Delete this template?"

  sig { params(template: ContentTemplatePresenter).void }
  def initialize(template:)
    @template = T.let(template, ContentTemplatePresenter)
  end

  sig { returns(ContentTemplatePresenter) }
  attr_reader :template
end
