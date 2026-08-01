# typed: strict

# One row in the Roster: a monogram avatar, a name (with an optional GM crown),
# a "Played by {player}" sub-line, and a trailing slot for a badge or action.
# Rows can be dimmed (removed / banned). Used for character rows and the GM-only
# banned section alike.
class Shared::RosterRowComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      name: String,
      subtitle: String,
      avatar_tone: Symbol,
      crown: T::Boolean,
      dimmed: T::Boolean,
      last: T::Boolean,
      name_class: String,
      subtitle_class: String
    ).void
  end
  def initialize(name:, subtitle:, avatar_tone: :gold, crown: false, dimmed: false, last: false,
                 name_class: "text-ink", subtitle_class: "text-muted-2")
    @name = name
    @subtitle = subtitle
    @avatar_tone = avatar_tone
    @crown = crown
    @dimmed = dimmed
    @last = last
    @name_class = name_class
    @subtitle_class = subtitle_class
  end

  sig { returns(String) }
  attr_reader :name

  sig { returns(String) }
  attr_reader :subtitle

  sig { returns(Symbol) }
  attr_reader :avatar_tone

  sig { returns(T::Boolean) }
  def crown?
    @crown
  end

  sig { returns(String) }
  def name_classes
    "flex items-center gap-1.5 text-[13px] font-semibold #{@name_class}"
  end

  sig { returns(String) }
  def subtitle_classes
    "text-[11px] #{@subtitle_class}"
  end

  sig { returns(String) }
  def row_classes
    base = "flex items-center gap-2.5 p-[10px_12px]"
    base += " border-b border-card-divider" unless @last
    base += " opacity-70" if @dimmed
    base
  end
end
