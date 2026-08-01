# typed: strict

# The screen scaffold every redesigned page composes: a fixed-width mobile frame
# with a dark `header` slot, a scrolling light `body` (the default content), and
# an optional pinned `footer` slot (e.g. the "+ New Game" / "Invite Player"
# button bar). Keeps frame structure in one place so no screen re-invents it.
class Shared::MobileFrameComponent < ApplicationComponent
  extend T::Sig

  renders_one :header
  renders_one :footer
end
