# typed: strict

# Uppercase muted section label — the small "ACTIVE SCENES" / "CHARACTERS"
# heading that groups content on every screen.
class Ui::SectionLabelComponent < ApplicationComponent
  extend T::Sig

  BASE = T.let(
    "text-[11px] font-bold text-muted uppercase tracking-[0.05em]",
    String
  )

  sig { params(html_class: String).void }
  def initialize(html_class: "")
    @html_class = html_class
  end

  sig { returns(String) }
  def classes
    @html_class.empty? ? BASE : "#{BASE} #{@html_class}"
  end
end
