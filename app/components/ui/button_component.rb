# typed: true

class Ui::ButtonComponent < ApplicationComponent
  VARIANTS = T.let({
    primary:   "bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500",
    secondary: "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50",
    danger:    "bg-red-600 text-white hover:bg-red-700 focus:ring-red-500",
    ghost:     "text-gray-500 hover:text-gray-700 hover:bg-gray-100"
  }.freeze, T::Hash[Symbol, String])

  SIZES = T.let({
    sm: "px-3 py-1.5 text-sm",
    md: "px-4 py-2 text-sm",
    lg: "px-6 py-3 text-base"
  }.freeze, T::Hash[Symbol, String])

  BASE = T.let(
    "inline-flex items-center justify-center rounded-md font-medium " \
    "focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors",
    String
  )

  sig { params(variant: Symbol, size: Symbol, disabled: T::Boolean).void }
  def initialize(variant: :primary, size: :md, disabled: false)
    @variant  = variant
    @size     = size
    @disabled = disabled
  end

  sig { returns(String) }
  def classes
    parts = [ BASE, VARIANTS.fetch(@variant), SIZES.fetch(@size) ]
    parts << "opacity-50 cursor-not-allowed" if @disabled
    parts.join(" ")
  end
end
