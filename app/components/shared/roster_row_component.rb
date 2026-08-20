# typed: strict

# One row in the Roster: an identity block (monogram avatar, a name with an
# optional GM crown, a "Played by {player}" sub-line) plus a trailing slot for a
# badge or action. Rows can be inactive (removed / banned), which dims them.
# Used for character rows and the GM-only banned section alike.
#
# The row's display data travels as one Row hash rather than several positional
# parameters — callers build it from whichever source they have (a presenter, a
# hardcoded GM row, a plain hash). It carries domain/state facts only
# (`crown:`, `active:`, a colour `variant:`); the identity block owns every CSS
# class. `position` stays a separate parameter: it is the row's position in the
# list the caller is rendering, not a fact about the row's own data.
class Shared::RosterRowComponent < ApplicationComponent
  extend T::Sig

  Row = T.type_alias do
    {
      name: String,
      subtitle: String,
      avatar_tone: Symbol,
      crown: T::Boolean,
      active: T::Boolean,
      variant: Symbol
    }
  end

  DEFAULT_ROW = T.let({
    avatar_tone: :gold,
    crown: false,
    active: true,
    variant: :default
  }.freeze, T::Hash[Symbol, T.untyped])

  POSITIONS = T.let(%i[middle last].freeze, T::Array[Symbol])

  sig { params(row: T::Hash[Symbol, T.untyped], position: Symbol).void }
  def initialize(row:, position: :middle)
    raise ArgumentError, "Unknown position: #{position}" unless POSITIONS.include?(position)

    @row = T.let(T.cast(DEFAULT_ROW.merge(row), Row), Row)
    @position = position
  end

  sig { returns(String) }
  def name
    @row.fetch(:name)
  end

  sig { returns(String) }
  def subtitle
    @row.fetch(:subtitle)
  end

  sig { returns(Symbol) }
  def avatar_tone
    @row.fetch(:avatar_tone)
  end

  sig { returns(T::Boolean) }
  def crown?
    @row.fetch(:crown)
  end

  sig { returns(T::Boolean) }
  def active?
    @row.fetch(:active)
  end

  sig { returns(Symbol) }
  def variant
    @row.fetch(:variant)
  end

  sig { returns(String) }
  def row_classes
    base = "flex items-center gap-2.5 p-[10px_12px]"
    base += " border-b border-card-divider" unless @position == :last
    base += " opacity-70" unless active?
    base
  end
end
