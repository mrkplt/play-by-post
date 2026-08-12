# typed: strict

class Ui::BadgeComponent < ApplicationComponent
  VARIANTS = T.let({
    # Light-page tints (existing callers)
    yellow: "bg-yellow-100 text-yellow-800",
    gray:   "bg-slate-100 text-slate-600",
    green:  "bg-green-100 text-green-800",
    blue:   "bg-blue-100 text-blue-800",
    # Dark-surface tints from the mobile redesign (Removed / Banned pills on
    # dark headers and roster rows). Uppercase, letter-spaced.
    slate:  "bg-sidebar-bg text-muted-2 border border-sidebar-border uppercase tracking-[0.03em]",
    danger: "bg-badge-danger-bg text-badge-danger-text border border-badge-danger-border uppercase tracking-[0.03em]",
    goldish: "bg-badge-gold-bg text-badge-gold-text border border-badge-gold-border uppercase tracking-[0.03em]"
  }.freeze, T::Hash[Symbol, String])

  BASE = T.let(
    "inline-block px-2 py-0.5 rounded-full text-xs font-semibold",
    String
  )

  sig { params(variant: Symbol).void }
  def initialize(variant: :gray)
    @variant = variant
  end

  sig { returns(String) }
  def classes
    "#{BASE} #{VARIANTS.fetch(@variant)}"
  end
end
