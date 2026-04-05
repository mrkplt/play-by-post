# typed: strict

class Ui::BadgeComponent < ApplicationComponent
  VARIANTS = T.let({
    yellow: "bg-yellow-100 text-yellow-800",
    gray:   "bg-slate-100 text-slate-600",
    green:  "bg-green-100 text-green-800",
    blue:   "bg-blue-100 text-blue-800"
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
