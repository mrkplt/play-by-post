# typed: strict

# Domain-specific icon component that maps semantic names to icon library glyphs.
# Centralizes icon naming so the app isn't coupled to Hugeicons internals.
class Ui::IconComponent < ApplicationComponent
  extend T::Sig

  # Domain name → Hugeicons name
  ICON_MAP = T.let({
    crown: "crown-03",
    settings: "settings-01",
    cancel: "cancel-01",
    help: "help-circle"
  }.freeze, T::Hash[Symbol, String])

  # Size variants
  SIZES = T.let({
    small: "w-4 h-4",
    medium: "w-5 h-5",
    extra_small: "w-[13px] h-[13px]"
  }.freeze, T::Hash[Symbol, String])

  EMPHASES = T.let(%i[normal accent].freeze, T::Array[Symbol])

  sig do
    params(
      name: Symbol,
      size: Symbol,
      emphasis: Symbol,
      html_options: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(name:, size: :small, emphasis: :normal, html_options: {})
    raise ArgumentError, "Unknown emphasis: #{emphasis}" unless EMPHASES.include?(emphasis)

    @name = name
    @size = size
    @emphasis = emphasis
    @html_options = html_options
  end

  sig { returns(String) }
  def call
    icon_name = ICON_MAP.fetch(@name) { raise ArgumentError, "Unknown icon: #{@name}" }
    helpers.icon(icon_name, **build_options)
  end

  private

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def build_options
    merged = { class: icon_classes }.merge(@html_options)
    merged.delete(:class) if merged[:class].to_s.empty?
    merged
  end

  # The size/accent/caller classes, with any caller-supplied
  # `html_options[:class]` folded in and removed from html_options so it
  # isn't merged in twice.
  sig { returns(String) }
  def icon_classes
    classes = [ size_class ]
    classes << "text-accent" if @emphasis == :accent
    # `@html_options[:class]` gates entry, so the deleted value is always truthy.
    classes << T.unsafe(@html_options.delete(:class)) if @html_options[:class]
    classes.join(" ")
  end

  sig { returns(String) }
  def size_class
    SIZES.fetch(@size) { raise ArgumentError, "Unknown size: #{@size}" }
  end
end
