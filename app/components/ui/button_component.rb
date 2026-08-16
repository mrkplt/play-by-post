# typed: strict

# The single button primitive: token-styled, four variants, three sizes, and
# two render paths.
#
#   - No `link:` (or a Link with no `url:`) — renders a plain <button>. Used
#     inside a `form_with` block as the submit control (pass
#     `type: "submit"` via `html_options`), or as a bare in-page control the
#     caller wires up with Stimulus.
#   - `link:` carries a `url:` — renders a Rails `link_to` styled as a
#     button. See button_component/link.rb and button_component/style.rb for
#     the two configuration bundles this component takes instead of eight
#     separate parameters.
class Ui::ButtonComponent < ApplicationComponent
  extend T::Sig

  VARIANTS = T.let({
    primary:   "bg-accent text-accent-ink",
    secondary: "border border-card-border text-ink bg-transparent",
    danger:    "border border-card-border text-danger bg-transparent",
    text:      "bg-transparent border-0 p-0 cursor-pointer text-accent"
  }.freeze, T::Hash[Symbol, String])

  SIZES = T.let({
    sm: "px-3 py-1.5 text-[11px]",
    md: "px-4 py-2.5 text-[13px]",
    lg: "px-6 py-3 text-base"
  }.freeze, T::Hash[Symbol, String])

  BASE = T.let(
    "inline-flex items-center justify-center rounded-control font-bold " \
    "no-underline transition-colors",
    String
  )

  sig { params(style: Style, link: Link, html_options: T::Hash[Symbol, T.untyped]).void }
  def initialize(style: Style.new, link: Link.new, html_options: {})
    @style = style
    @link = link
    @html_options = html_options
  end

  sig { returns(T::Boolean) }
  def link?
    @link.present?
  end

  sig { returns(String) }
  def url
    T.must(@link.url)
  end

  sig { returns(String) }
  def classes
    parts = [ BASE, VARIANTS.fetch(@style.variant), SIZES.fetch(@style.size) ]
    parts << "opacity-50 cursor-not-allowed pointer-events-none" if @style.disabled?
    parts.join(" ")
  end

  # A link with method: performs a non-GET action (the same thing button_to
  # would do), not a navigation — role="button" reflects that for assistive
  # tech and lets it be found/clicked as a button in tests, same as a real
  # <button>. A plain GET link (no method:, e.g. Cancel) stays an unadorned
  # link.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_options
    opts = { class: merged_classes, data: @link.data_attributes }.merge(@html_options.except(:class))
    opts[:role] = "button" if @link.http_method
    opts
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def button_options
    opts = { type: "button", class: merged_classes }.merge(@html_options.except(:class))
    opts[:disabled] = true if @style.disabled?
    opts
  end

  # `html_options[:class]` is additive (e.g. a caller-supplied text-color
  # override) — it must not replace the base/variant/size classes.
  sig { returns(String) }
  def merged_classes
    extra = @html_options[:class]
    extra.present? ? "#{classes} #{extra}" : classes
  end
end
