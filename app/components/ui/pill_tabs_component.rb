# typed: strict

# Horizontal pill-tab navigation used in the dark game header. The active tab is
# gold-filled; inactive tabs are muted.
#
# Two modes:
#   :link   — tabs are anchors to `href` (cross-page navigation).
#   :switch — tabs are buttons that toggle in-page panels via the `game-tabs`
#             Stimulus controller (no navigation); each tab names a `panel`.
class Ui::PillTabsComponent < ApplicationComponent
  extend T::Sig

  class Tab < T::Struct
    const :label, String
    const :href, String, default: "#"
    const :panel, T.nilable(Symbol), default: nil
  end

  ACTIVE = T.let("bg-accent text-accent-ink", String)
  IDLE = T.let("bg-pill-idle text-sidebar-text", String)
  BASE = T.let(
    "text-[11px] font-bold px-3 py-1.5 rounded-[20px] no-underline cursor-pointer border-0",
    String
  )

  sig { params(tabs: T::Array[Tab], active: Symbol, mode: Symbol).void }
  def initialize(tabs:, active:, mode: :link)
    @tabs = tabs
    @active = active
    @mode = mode
  end

  sig { returns(T::Array[Tab]) }
  attr_reader :tabs

  sig { returns(T::Boolean) }
  def switch?
    @mode == :switch
  end

  sig { params(tab: Tab).returns(T::Boolean) }
  def active?(tab)
    tab.label.downcase.to_sym == @active
  end

  sig { params(tab: Tab).returns(String) }
  def tab_classes(tab)
    "#{BASE} #{active?(tab) ? ACTIVE : IDLE}"
  end

  sig { params(tab: Tab).returns(T.nilable(String)) }
  def aria_current(tab)
    active?(tab) ? "page" : nil
  end

  sig { params(tab: Tab).returns(String) }
  def panel_name(tab)
    T.must(tab.panel).to_s
  end
end
