# typed: strict

# A settings/list row: label (+ optional sub-label) on the left, a control slot
# on the right, with a bottom divider. Used throughout Player Management and
# Profile. The right-hand control is supplied as the block content.
#
# `control:` picks the control container's flex behaviour: :fixed (default)
# protects intrinsic-width controls (toggles, buttons) from being squeezed by a
# long label; :shrink lets a width-flexible control (a secret field's input)
# compress instead of overflowing the row on narrow viewports.
class Ui::SettingsRowComponent < ApplicationComponent
  extend T::Sig

  POSITIONS = T.let(%i[middle last].freeze, T::Array[Symbol])

  CONTROL_LAYOUTS = T.let({
    fixed: "flex items-center gap-3 flex-shrink-0",
    shrink: "flex items-center gap-3 min-w-0"
  }.freeze, T::Hash[Symbol, String])

  sig { params(label: String, sub: T.nilable(String), position: Symbol, control: Symbol).void }
  def initialize(label:, sub: nil, position: :middle, control: :fixed)
    raise ArgumentError, "Unknown position: #{position}" unless POSITIONS.include?(position)

    @label = label
    @sub = sub
    @position = position
    @control_classes = T.let(CONTROL_LAYOUTS.fetch(control), String)
  end

  sig { returns(String) }
  attr_reader :control_classes

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
