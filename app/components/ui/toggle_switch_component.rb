# typed: strict

# Binary on/off toggle switch — thumb slides left (off) / right (on).
# Presentational only; the caller wires the click behaviour (Stimulus action,
# button_to, etc.) via the block content placed beside it or a wrapping form.
class Ui::ToggleSwitchComponent < ApplicationComponent
  extend T::Sig

  sig { params(on: T::Boolean, html_class: String).void }
  def initialize(on: false, html_class: "")
    @on = on
    @html_class = html_class
  end

  sig { returns(T::Boolean) }
  def on?
    @on
  end

  sig { returns(String) }
  def track_classes
    base = "w-8 h-[18px] rounded-[9px] relative transition-colors duration-150 flex-shrink-0"
    tone = on? ? "bg-accent" : "bg-[#3a3c42]"
    [ base, tone, @html_class ].reject(&:empty?).join(" ")
  end

  sig { returns(String) }
  def thumb_classes
    base = "w-[14px] h-[14px] rounded-full bg-white absolute top-0.5 transition-all duration-150"
    pos = on? ? "right-0.5" : "left-0.5"
    "#{base} #{pos}"
  end
end
