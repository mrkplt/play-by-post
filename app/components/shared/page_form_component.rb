# typed: strict

# The New Page / Edit Page form, built on the mobile-first component system.
# Both entry points share a title field and a markdown body editor (formatting
# toolbar + live preview). The component derives its rendering mode (new vs
# edit), labels, and back-href from the page it is handed, so the view renders
# it with just the game and the page — no form-construction logic in the
# template. The slug is generated server-side and never shown or edited here.
class Shared::PageFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, page: Page).void }
  def initialize(game:, page:)
    @game = T.let(game, Game)
    @page = T.let(page, Page)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Page) }
  attr_reader :page

  sig { returns(T::Boolean) }
  def new_record?
    @page.new_record?
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Page" : "Save"
  end

  sig { returns(String) }
  def back_href
    new_record? ? helpers.game_path(@game, anchor: "pages") : helpers.game_page_path(@game, @page)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "new_page_form" : "edit_page_#{T.must(@page.id)}_form"
  end

  sig { returns(T::Boolean) }
  def errors?
    @page.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @page.errors.full_messages
  end
end
