# typed: strict

# Avatar — a circular identity glyph. When an `image_url` is given (an uploaded
# player avatar or character portrait) it renders that image; otherwise it falls
# back to the monogram, an initial letter on a solid circle. Gold for players,
# dark for the GM, muted for removed/banned rows.
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

  sig { params(name: String, tone: Symbol, size: Symbol, image_url: T.nilable(String)).void }
  def initialize(name:, tone: :gold, size: :md, image_url: nil)
    @name = name
    @tone = tone
    @size = size
    @image_url = image_url
  end

  sig { returns(T::Boolean) }
  def image?
    @image_url.present?
  end

  sig { returns(String) }
  def image_url
    T.must(@image_url)
  end

  sig { returns(String) }
  def initial
    # slice(0, 1) is typed nilable by Sorbet, so .to_s guards it; at runtime it
    # is always a String ("" for a blank name). The .to_s-removal mutant is
    # therefore equivalent and left alive.
    @name.strip.slice(0, 1).to_s.upcase
  end

  # The <img>'s size/shape classes only — the monogram's tone (background/text
  # colour) is meaningless behind a photo, so an image avatar drops it.
  sig { returns(String) }
  def image_classes
    "#{BASE} #{SIZES.fetch(@size)} object-cover"
  end

  sig { returns(String) }
  def classes
    "#{BASE} #{SIZES.fetch(@size)} #{TONES.fetch(@tone)}"
  end
end
