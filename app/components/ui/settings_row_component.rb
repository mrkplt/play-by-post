# typed: strict

# A settings/list row: label (+ optional sub-label) on the left, a control slot
# on the right, with a bottom divider. Used throughout Player Management and
# Profile. The right-hand control is supplied as the block content.
class Ui::SettingsRowComponent < ApplicationComponent
  extend T::Sig

  POSITIONS = T.let(%i[middle last].freeze, T::Array[Symbol])

  sig { params(label: String, sub: T.nilable(String), position: Symbol).void }
  def initialize(label:, sub: nil, position: :middle)
    raise ArgumentError, "Unknown position: #{position}" unless POSITIONS.include?(position)

    @label = label
    @sub = sub
    @position = position
  end

  sig { returns(String) }
  attr_reader :label

  sig { returns(T.nilable(String)) }
  attr_reader :sub

  sig { returns(String) }
  def row_classes
    base = "flex justify-between items-center py-3 gap-2.5"
    @position == :last ? base : "#{base} border-b border-card-divider"
  end
end
