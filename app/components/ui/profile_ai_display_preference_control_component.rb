# typed: strict

# The per-user AI DISPLAY preference control on the Profile screen (AI Control
# Plane): a 3-state segmented control (shown / tagged / hidden), independent
# of Ui::ProfileAiConsentToggleComponent's on/off consent switch — display is
# about consuming AI-generated assets, not producing them. Like the consent
# toggle, this has no client-side behaviour to drive (no filtering to apply
# immediately), so each option is a plain server round-trip (button_to)
# rather than a Stimulus controller. Options are parameterized off
# UserProfile's own enum keys/labels rather than duplicated here, so a new
# state added to the enum only needs a label added to OPTIONS.
class Ui::ProfileAiDisplayPreferenceControlComponent < ApplicationComponent
  extend T::Sig

  class Option < T::Struct
    const :value, String
    const :label, String
  end

  OPTIONS = T.let(
    [
      Option.new(value: "shown", label: "Shown"),
      Option.new(value: "tagged", label: "Tagged"),
      Option.new(value: "hidden", label: "Hidden")
    ].freeze,
    T::Array[Option]
  )

  # Active/idle tones and the pill-row wrapper are the same visual language as
  # Ui::PillTabsComponent (gold-filled active pill among muted idles) —
  # referenced rather than re-declared so the two can't drift apart.
  BASE = T.let(
    "text-[11px] font-bold px-3 py-1.5 rounded-pill cursor-pointer border-0",
    String
  )

  sig { params(preference: String, update_url: String).void }
  def initialize(preference:, update_url:)
    @preference = preference
    @update_url = update_url
  end

  sig { returns(T::Array[Option]) }
  def options
    OPTIONS
  end

  sig { returns(String) }
  attr_reader :update_url

  sig { params(option: Option).returns(T::Boolean) }
  def active?(option)
    option.value == @preference
  end

  sig { params(option: Option).returns(String) }
  def option_classes(option)
    tone = active?(option) ? Ui::PillTabsComponent::ACTIVE : Ui::PillTabsComponent::IDLE
    "#{BASE} #{tone}"
  end

  sig { returns(String) }
  def wrapper_classes
    Ui::PillTabsComponent::WRAPPER_CLASSES
  end

  sig { params(option: Option).returns(T::Boolean) }
  def aria_pressed(option)
    active?(option)
  end
end
