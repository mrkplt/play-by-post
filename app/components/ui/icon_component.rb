# typed: strict

# Domain-specific icon component that maps semantic names to icon library glyphs.
# Centralizes icon naming so the app isn't coupled to Hugeicons internals.
class Ui::IconComponent < ApplicationComponent
  extend T::Sig

  # Domain name → Hugeicons name
  ICON_MAP = T.let({
    crown: "crown-03",
    settings: "settings-01",
    cancel: "cancel-01"
  }.freeze, T::Hash[Symbol, String])

  # Size variants
  SIZES = T.let({
    small: "w-4 h-4",
    medium: "w-5 h-5",
    extra_small: "w-[13px] h-[13px]"
  }.freeze, T::Hash[Symbol, String])

  sig do
    params(
      name: Symbol,
      size: Symbol,
      accent: T::Boolean,
      html_options: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(name:, size: :small, accent: false, html_options: {})
    @name = name
    @size = size
    @accent = accent
    @html_options = html_options
  end

  sig { returns(String) }
  def call
    icon_name = ICON_MAP.fetch(@name) { raise ArgumentError, "Unknown icon: #{@name}" }
    options = build_options
    if options.empty?
      helpers.icon(icon_name)
    else
      helpers.icon(icon_name, **options)
    end
  end

  private

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def build_options
    classes = [ size_class ]
    classes << "text-accent" if @accent
    if @html_options[:class]
      custom_class = T.unsafe(@html_options.delete(:class))
      classes << custom_class if custom_class
    end
    merged = { class: classes.compact.join(" ") }.merge(@html_options)
    merged.delete(:class) if merged[:class].to_s.empty?
    merged
  end

  sig { returns(String) }
  def size_class
    SIZES.fetch(@size) { raise ArgumentError, "Unknown size: #{@size}" }
  end
end
