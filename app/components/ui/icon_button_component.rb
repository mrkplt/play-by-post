# typed: strict

# Icon-only tap target sized to a real 44px-tall touch target (hard rule from
# the redesign spec). Renders as a link when `href` is given, else a button.
# The glyph/icon is supplied as block content so callers can pass a HugeIcon or
# a Unicode glyph.
class Ui::IconButtonComponent < ApplicationComponent
  extend T::Sig

  ALIGN = T.let({
    start: "justify-start",
    center: "justify-center"
  }.freeze, T::Hash[Symbol, String])

  BASE = T.let(
    "w-8 h-11 flex items-center flex-shrink-0 cursor-pointer bg-transparent border-0 " \
    "text-sidebar-text hover:opacity-75 p-0",
    String
  )

  sig do
    params(
      href: T.nilable(String),
      align: Symbol,
      label: String,
      html_options: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(href: nil, align: :start, label: "", html_options: {})
    @href = href
    @align = align
    @label = label
    @html_options = html_options
  end

  sig { returns(T.nilable(String)) }
  attr_reader :href

  sig { returns(String) }
  def classes
    "#{BASE} #{ALIGN.fetch(@align)}"
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_options
    { class: classes, "aria-label": @label }.merge(@html_options)
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def button_options
    { type: "button", class: classes, "aria-label": @label }.merge(@html_options)
  end
end
