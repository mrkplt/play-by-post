# typed: strict

# One tab panel of the game screen's Shared::GameTabsComponent shell: renders the
# `data-game-tabs-target="panel"` section the tab controller shows and hides.
# `name` is how the pills and URL hash address the panel; `visibility:` is
# `:shown` for the panel visible before the controller connects (and the
# fallback when the URL hash names no panel) or `:hidden` for the rest, which
# start hidden. Owns the section markup so the six panels no longer repeat it.
class Shared::GameTabsComponent::PanelComponent < ApplicationComponent
  extend T::Sig

  VISIBILITIES = T.let(%i[shown hidden].freeze, T::Array[Symbol])

  sig { params(name: String, visibility: Symbol).void }
  def initialize(name:, visibility: :hidden)
    raise ArgumentError, "Unknown visibility: #{visibility}" unless VISIBILITIES.include?(visibility)

    @name = name
    @visibility = visibility
  end

  sig { returns(String) }
  attr_reader :name

  sig { returns(T::Boolean) }
  def hidden?
    @visibility == :hidden
  end
end
