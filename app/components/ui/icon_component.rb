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

  sig do
    params(
      name: Symbol,
      class: T.nilable(String),
      html_options: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(name:, class: nil, **html_options)
    @name = name
    @class = binding.local_variable_get(:class)
    @html_options = html_options
  end

  sig { returns(String) }
  def call
    icon_name = ICON_MAP.fetch(@name) { raise ArgumentError, "Unknown icon: #{@name}" }
    options = @class ? { class: @class }.merge(@html_options) : @html_options
    if options.empty?
      helpers.icon(icon_name)
    else
      helpers.icon(icon_name, **options)
    end
  end
end
