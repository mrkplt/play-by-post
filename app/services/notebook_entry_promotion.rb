# typed: strict
# frozen_string_literal: true

# Promoting a Campaign Notebook entry into a full game Page.
#
# Idempotent by design: an entry that already carries a promoted_page is
# returned as-is rather than creating a second Page. That guard is the whole
# reason this is a unit — "promote" is not "create a page", it is "ensure this
# entry has exactly one page", and the controller should not be the thing
# remembering that difference.
class NotebookEntryPromotion
  extend T::Sig

  sig { params(entry: NotebookEntry).void }
  def initialize(entry)
    @entry = entry
  end

  # The entry's page — the existing one when already promoted, otherwise a
  # newly created page with the entry marked done and linked to it.
  sig { returns(Page) }
  def call
    return T.must(@entry.promoted_page) if @entry.promoted?

    page = game.pages.create!(title: @entry.title, body: @entry.body)
    @entry.update!(status: "done", promoted_page: page)
    page
  end

  private

  sig { returns(Game) }
  def game
    T.must(@entry.game)
  end
end
