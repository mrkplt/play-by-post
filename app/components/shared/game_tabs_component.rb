# typed: strict

# The client-side tab shell for the game screen. Under `game-tabs` control it
# shows one panel at a time, gold-fills the active pill, and deep-links the
# active panel through the URL hash. The controller div wraps the mobile frame,
# whose body holds the panel sections (Shared::GameTabsComponent::PanelComponent);
# the panels must be descendants of this div for the controller to find them.
class Shared::GameTabsComponent < ApplicationComponent
  extend T::Sig
end
