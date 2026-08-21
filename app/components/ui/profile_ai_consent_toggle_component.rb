# typed: strict

# The per-user AI consent switch on the Profile screen (AI Control Plane):
# opts a user in/out of AI features for themselves, independent of any game's
# own ai_summaries_enabled toggle — see SceneResolution#call, which requires
# both to be on before a scene summary is generated. Unlike
# Ui::ProfileOocToggleComponent this has no client-side behaviour to drive (no
# filtering to apply immediately), so it is a plain server round-trip
# (button_to) rather than a Stimulus controller.
class Ui::ProfileAiConsentToggleComponent < ApplicationComponent
  extend T::Sig

  sig { params(consented: T::Boolean, toggle_url: String).void }
  def initialize(consented:, toggle_url:)
    @consented = consented
    @toggle_url = toggle_url
  end

  sig { returns(T::Boolean) }
  def consented?
    @consented
  end

  sig { returns(String) }
  attr_reader :toggle_url

  sig { returns(String) }
  def aria_label
    consented? ? "Disable AI features for your games" : "Enable AI features for your games"
  end

  # The switch's on/off state as Ui::ToggleSwitchComponent expects it —
  # extracted so the ERB template has no ternary in its output tag
  # (bin/quality-metrics' ERB-logic check).
  sig { returns(Symbol) }
  def toggle_state
    consented? ? :on : :off
  end
end
