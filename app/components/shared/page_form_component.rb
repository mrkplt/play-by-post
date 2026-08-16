# typed: strict

# The New Page / Edit Page form, built on the mobile-first component system.
# Both entry points share a title field and a markdown body editor (formatting
# toolbar + live preview). The component derives its rendering mode (new vs
# edit), labels, and back-href from the presenter it is handed, so the view
# renders it with just the presenter — no form-construction logic in the
# template. The slug is generated server-side and never shown or edited here.
class Shared::PageFormComponent < ApplicationComponent
  extend T::Sig
  include Shared::RecordBackedForm

  sig { params(page: PagePresenter).void }
  def initialize(page:)
    @page = T.let(page, PagePresenter)
  end

  sig { returns(Game) }
  def game
    @page.game
  end

  sig { returns(PagePresenter) }
  attr_reader :page

  sig { override.returns(PagePresenter) }
  def record
    @page
  end

  sig { returns(String) }
  def submit_label
    mode_value(new: "Create Page", edit: "Save")
  end

  sig { returns(String) }
  def back_href
    mode_value(
      new: -> { helpers.game_path(game, anchor: "pages") },
      edit: -> { helpers.game_page_path(game, @page) }
    ).call
  end

  sig { returns(String) }
  def form_id
    mode_value(new: "new_page_form", edit: "edit_page_#{@page.id}_form")
  end

  # Live draft autosave applies only to a persisted page — a new page has no row
  # to autosave onto, so its draft state is chosen at create via the toggle.
  sig { returns(T::Boolean) }
  def autosave?
    !new_record?
  end

  # Where the editor autosaves this page's draft (edit only).
  sig { returns(String) }
  def save_draft_path
    page.routes.save_draft_path
  end

  # Whether this page is currently an unpublished draft — sets the toggle's
  # initial state on edit.
  sig { returns(T::Boolean) }
  def draft?
    page.draft?
  end

  private

  # The single new_record?-keyed branch every mode-dependent value goes
  # through, so the form's new/edit distinction is tested once per call
  # rather than re-testing new_record? in each label/href/id method.
  sig { type_parameters(:T).params(new: T.type_parameter(:T), edit: T.type_parameter(:T)).returns(T.type_parameter(:T)) }
  def mode_value(new:, edit:)
    new_record? ? new : edit
  end
end
