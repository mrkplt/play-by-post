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
    new_record? ? "Create Page" : "Save"
  end

  sig { returns(String) }
  def back_href
    new_record? ? helpers.game_path(game, anchor: "pages") : helpers.game_page_path(game, @page)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "new_page_form" : "edit_page_#{@page.id}_form"
  end
end
