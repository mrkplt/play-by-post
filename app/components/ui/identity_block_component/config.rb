# typed: strict

# The presentation configuration for an identity block: orientation, colour
# variant, size step, avatar tone/size, and the crown/active state flags.
# Grouped into one value object (the same pattern as Ui::ButtonComponent::Style)
# so the component takes name + labels + this bundle rather than a long loose
# parameter list — and so the state→CSS mapping lives in one place. Callers pass
# domain/state facts; this object decides every class.
class Ui::IdentityBlockComponent::Config < T::Struct
  extend T::Sig

  # Colour context for the two labels — mapped to concrete token classes so
  # callers never name a colour. The valid orientation/variant/size sets are the
  # key sets of the mapping tables below, so they are not duplicated as separate
  # constants; #validate! checks membership against those keys.
  PRIMARY_COLOUR = T.let({
    default: "text-ink",
    blue: "text-tint-blue-strong",
    on_dark: "text-white"
  }.freeze, T::Hash[Symbol, String])

  SECONDARY_COLOUR = T.let({
    default: "text-muted-2",
    blue: "text-tint-blue-soft",
    on_dark: "text-muted"
  }.freeze, T::Hash[Symbol, String])

  PRIMARY_SIZE = T.let({
    sm: "font-bold text-[11px] leading-tight",
    md: "text-[13px] font-semibold",
    lg: "text-[15px] font-semibold"
  }.freeze, T::Hash[Symbol, String])

  SECONDARY_SIZE = T.let({
    sm: "text-[11px]",
    md: "text-[11px]",
    lg: "text-[11px]"
  }.freeze, T::Hash[Symbol, String])

  ORIENTATION_CLASSES = T.let({
    stacked: "flex flex-col items-center gap-[3px]",
    inline: "flex items-center gap-2.5"
  }.freeze, T::Hash[Symbol, String])

  const :orientation, Symbol, default: :inline
  const :variant, Symbol, default: :default
  const :size, Symbol, default: :md
  const :avatar_tone, Symbol, default: :gold
  const :avatar_size, Symbol, default: :lg
  const :crown, T::Boolean, default: false
  const :active, T::Boolean, default: true

  sig { void }
  def validate!
    raise ArgumentError, "Unknown orientation: #{orientation}" unless ORIENTATION_CLASSES.key?(orientation)
    raise ArgumentError, "Unknown variant: #{variant}" unless PRIMARY_COLOUR.key?(variant)
    raise ArgumentError, "Unknown size: #{size}" unless PRIMARY_SIZE.key?(size)
  end

  sig { returns(String) }
  def wrapper_classes
    base = ORIENTATION_CLASSES.fetch(orientation)
    active ? base : "#{base} opacity-70"
  end

  # Inline labels sit in a shrinkable column beside the avatar; stacked labels
  # are centered by the wrapper.
  sig { returns(String) }
  def labels_classes
    orientation == :inline ? "flex flex-col flex-1 min-w-0" : "flex flex-col items-center"
  end

  sig { returns(String) }
  def primary_classes
    [ primary_layout, PRIMARY_SIZE.fetch(size), PRIMARY_COLOUR.fetch(variant) ].compact.join(" ")
  end

  sig { returns(String) }
  def secondary_classes
    "#{SECONDARY_SIZE.fetch(size)} #{SECONDARY_COLOUR.fetch(variant)}"
  end

  private

  # A crown seats an icon beside the text, so the label becomes a flex row;
  # otherwise stacked labels center and inline labels get no layout class at all
  # (nil, which primary_classes compacts away).
  sig { returns(T.nilable(String)) }
  def primary_layout
    return "flex items-center gap-1.5" if crown

    "text-center" if orientation == :stacked
  end
end
