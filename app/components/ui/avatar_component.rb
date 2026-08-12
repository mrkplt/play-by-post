# typed: strict

# Monogram avatar — an initial letter on a solid circle. Placeholder for
# real avatar uploads. Gold for players, dark for the GM, muted for
# removed/banned rows.
class Ui::AvatarComponent < ApplicationComponent
  extend T::Sig

  TONES = T.let({
    gold:  "bg-accent text-accent-ink",
    dark:  "bg-pill-idle text-sidebar-text",
    muted: "bg-avatar-muted text-ink",
    blue:  "bg-avatar-blue text-tint-blue-strong"
  }.freeze, T::Hash[Symbol, String])

  SIZES = T.let({
    sm: "w-[26px] h-[26px] text-[11px]",
    md: "w-7 h-7 text-xs",
    lg: "w-10 h-10 text-sm"
  }.freeze, T::Hash[Symbol, String])

  BASE = T.let(
    "rounded-full flex items-center justify-center font-bold flex-shrink-0",
    String
  )

  sig { params(name: String, tone: Symbol, size: Symbol).void }
  def initialize(name:, tone: :gold, size: :md)
    @name = name
    @tone = tone
    @size = size
  end

  sig { returns(String) }
  def initial
    # slice(0, 1) is typed nilable by Sorbet, so .to_s guards it; at runtime it
    # is always a String ("" for a blank name). The .to_s-removal mutant is
    # therefore equivalent and left alive.
    @name.strip.slice(0, 1).to_s.upcase
  end

  sig { returns(String) }
  def classes
    "#{BASE} #{SIZES.fetch(@size)} #{TONES.fetch(@tone)}"
  end
end
