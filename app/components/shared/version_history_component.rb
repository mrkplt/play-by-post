# typed: strict

# The collapsible version-history table shared by characters and pages: one row
# per snapshot linking to the historical version, with the editor's name. The
# two record types differ only in the per-row link path, so each supplies its
# rows (path + timestamps + editor) and this component owns the identical table
# markup — keeping that styling in one place rather than duplicated per record.
class Shared::VersionHistoryComponent < ApplicationComponent
  extend T::Sig

  # One history row: the version's own URL plus the values the table renders.
  class Row < T::Struct
    const :path, String
    const :timestamp, String
    const :formatted, String
    const :editor, String
  end

  sig { params(rows: T::Array[Row]).void }
  def initialize(rows:)
    @rows = T.let(rows, T::Array[Row])
  end

  sig { returns(T::Array[Row]) }
  attr_reader :rows

  sig { returns(Integer) }
  def version_count
    rows.size
  end
end
