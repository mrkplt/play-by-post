# typed: strict

# The per-viewer "Mute / Unmute notifications" button on the scene screen, in a
# stable id so ScenesController swaps just this control in place after a toggle
# (its label is the only change). Rendered on the scene page and re-rendered by
# ScenesController#toggle_notification_preference.
class Shared::MuteToggleComponent < ApplicationComponent
  extend T::Sig

  # The stable wrapper id the page renders and the in-place update targets.
  DOM_ID = "mute_toggle"

  sig { params(toggle_url: String, muted: T::Boolean).void }
  def initialize(toggle_url:, muted:)
    @toggle_url = toggle_url
    @muted = muted
  end

  sig { returns(String) }
  attr_reader :toggle_url

  sig { returns(String) }
  def label
    @muted ? "Unmute notifications" : "Mute notifications"
  end
end
