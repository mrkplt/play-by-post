# typed: strict

# The single button primitive: token-styled, four variants, three sizes, and
# two render paths.
#
#   - No `url:` — renders a plain <button>. Used inside a `form_with` block
#     as the submit control (pass `type: "submit"` via `html_options`), or as
#     a bare in-page control the caller wires up with Stimulus.
#   - `url:` given — renders a Rails `link_to` styled as a button, with
#     `method:`/`confirm:` passed through as `data-turbo-method` /
#     `data-turbo-confirm` (Rails 8 Turbo's non-GET-link and confirm-dialog
#     mechanism — the same behavior `button_to`/`f.submit data: { confirm: }`
#     produce). Extra `data:` is merged in, caller keys winning on conflict.
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

  sig do
    params(
      variant: Symbol,
      size: Symbol,
      disabled: T::Boolean,
      url: T.nilable(String),
      method: T.nilable(Symbol),
      confirm: T.nilable(String),
      data: T::Hash[Symbol, T.untyped],
      html_options: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(
    variant: :primary, size: :md, disabled: false,
    url: nil, method: nil, confirm: nil, data: {}, html_options: {}
  )
    @variant = variant
    @size = size
    @disabled = disabled
    @url = url
    @method = method
    @confirm = confirm
    @data = data
    @html_options = html_options
  end

  sig { returns(T::Boolean) }
  def link?
    @url.present?
  end

  sig { returns(String) }
  def url
    T.must(@url)
  end

  sig { returns(String) }
  def classes
    parts = [ BASE, VARIANTS.fetch(@variant), SIZES.fetch(@size) ]
    parts << "opacity-50 cursor-not-allowed pointer-events-none" if @disabled
    parts.join(" ")
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_data
    data = @data.dup
    data[:turbo_method] = @method if @method
    data[:turbo_confirm] = @confirm if @confirm
    data
  end

  # A link with method: performs a non-GET action (the same thing button_to
  # would do), not a navigation — role="button" reflects that for assistive
  # tech and lets it be found/clicked as a button in tests, same as a real
  # <button>. A plain GET link (no method:, e.g. Cancel) stays an unadorned
  # link.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_options
    opts = { class: merged_classes, data: link_data }.merge(@html_options.except(:class))
    opts[:role] = "button" if @method
    opts
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def button_options
    opts = { type: "button", class: merged_classes }.merge(@html_options.except(:class))
    opts[:disabled] = true if @disabled
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
