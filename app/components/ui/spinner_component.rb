# typed: strict

# A bare loading throbber — a spinning ring, sized on a fixed scale. It carries
# no text and no layout of its own; callers place it (e.g. inside
# Shared::AsyncPendingComponent's waiting row). Pure Tailwind, no co-located CSS.
class Ui::SpinnerComponent < ApplicationComponent
  extend T::Sig

  SIZES = T.let(
    {
      sm: "h-4 w-4 border-2",
      md: "h-6 w-6 border-2",
      lg: "h-8 w-8 border-[3px]"
    }.freeze,
    T::Hash[Symbol, String]
  )

  BASE = T.let(
    "inline-block animate-spin rounded-full border-card-border border-t-accent",
    String
  )

  sig { params(size: Symbol, label: String).void }
  def initialize(size: :md, label: "Loading")
    @size = size
    @label = label
  end

  sig { returns(String) }
  attr_reader :label

  sig { returns(String) }
  def classes
    "#{BASE} #{SIZES.fetch(@size)}"
  end
end
