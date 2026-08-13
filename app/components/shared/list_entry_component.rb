# typed: strict

# A grouped list of titled rows rendered as a single card: each row is a title
# linking somewhere, optionally followed by controls. Every row but the first
# carries a top divider, so the list reads as one card rather than separate
# cells.
#
# The component owns layout only. Rows arrive already derived — a title, a
# href, and a caller-built controls component (or nil) — so what a row links to
# and which controls it carries are the caller's decisions, not this
# component's. That is what lets the Pages list (title -> page, GM Edit/Delete)
# and the Notebook lanes (title -> edit, lane select) share it.
class Shared::ListEntryComponent < ApplicationComponent
  extend T::Sig

  # A presentation-ready row. `controls` renders after the title when present.
  Row = T.type_alias do
    {
      title: String,
      href: String,
      controls: T.nilable(ViewComponent::Base)
    }
  end

  ROW_BASE = T.let("flex items-center gap-2 px-4 py-3 no-underline", String)

  sig { params(rows: T::Array[Row], empty_text: String).void }
  def initialize(rows:, empty_text:)
    @rows = rows
    @empty_text = empty_text
  end

  sig { returns(T::Array[Row]) }
  attr_reader :rows

  sig { returns(String) }
  attr_reader :empty_text

  sig { returns(T::Boolean) }
  def any_rows?
    rows.any?
  end

  # Every row but the first carries a top divider, so the list reads as a
  # single grouped card rather than separate cells.
  sig { params(index: Integer).returns(String) }
  def row_classes(index)
    return ROW_BASE if index.zero?

    "#{ROW_BASE} border-t border-card-divider"
  end
end
