# typed: strict

# Uppercase muted section label — the small "ACTIVE SCENES" / "CHARACTERS"
# heading that groups content on every screen. Two size steps: :md (the default
# body-screen label) and :sm (the tighter, smaller label the nav drawer uses).
# `html_class` remains for caller-owned spacing/positioning only — never
# typography or colour (bin/check-component-css-args enforces this).
#
# An optional `action` slot renders inline at the trailing edge of the label
# row (e.g. a "View docs" link beside an "API tokens" heading) — the label and
# its action sit on one baseline-aligned row rather than stacking.
class Ui::SectionLabelComponent < ApplicationComponent
  extend T::Sig

  renders_one :action

  COLOUR = T.let("font-bold text-muted uppercase", String)

  SIZES = T.let({
    md: "text-[11px] tracking-[0.05em]",
    sm: "text-[10px] tracking-[0.06em]"
  }.freeze, T::Hash[Symbol, String])

  sig { params(size: Symbol, html_class: String).void }
  def initialize(size: :md, html_class: "")
    raise ArgumentError, "Unknown size: #{size}" unless SIZES.key?(size)

    @size = size
    @html_class = html_class
  end

  sig { returns(String) }
  def classes
    base = "#{SIZES.fetch(@size)} #{COLOUR}"
    @html_class.empty? ? base : "#{base} #{@html_class}"
  end
end
