# typed: strict

# The game secondary nav — instance #1 of Shared::HeaderComponent's
# secondary_nav slot. Wraps Ui::PillTabsComponent with the game section tab
# list (moved from the old Shared::GameHeaderComponent#tabs).
#
# Two modes:
#   :switch — today's client-side panel toggling on games/show (no navigation).
#   :link   — cross-page anchors to each section's own page, active tab
#             marked from the current section.
class Shared::GameNavComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, active_tab: Symbol, is_gm: T::Boolean, mode: Symbol).void }
  def initialize(game:, active_tab:, is_gm: false, mode: :switch)
    @game = game
    @active_tab = active_tab
    @is_gm = is_gm
    @mode = mode
  end

  sig { returns(Symbol) }
  attr_reader :active_tab

  sig { returns(Symbol) }
  attr_reader :mode

  sig { returns(T::Array[Ui::PillTabsComponent::Tab]) }
  def tabs
    base = [
      Ui::PillTabsComponent::Tab.new(label: "Scenes", href: scenes_href, panel: :scenes),
      Ui::PillTabsComponent::Tab.new(label: "Roster", href: roster_href, panel: :roster),
      Ui::PillTabsComponent::Tab.new(label: "Files", href: files_href, panel: :files),
      Ui::PillTabsComponent::Tab.new(label: "Pages", href: pages_href, panel: :pages),
      Ui::PillTabsComponent::Tab.new(label: "Links", href: links_href, panel: :links)
    ]
    base << Ui::PillTabsComponent::Tab.new(label: "Notebook", href: notebook_href, panel: :notebook) if @is_gm
    base
  end

  private

  sig { returns(String) }
  def scenes_href
    T.unsafe(helpers).game_scenes_path(@game)
  end

  sig { returns(String) }
  def roster_href
    T.unsafe(helpers).game_path(@game, anchor: "roster")
  end

  sig { returns(String) }
  def files_href
    T.unsafe(helpers).game_game_files_path(@game)
  end

  sig { returns(String) }
  def pages_href
    T.unsafe(helpers).game_path(@game, anchor: "pages")
  end

  sig { returns(String) }
  def links_href
    T.unsafe(helpers).game_game_links_path(@game)
  end

  sig { returns(String) }
  def notebook_href
    T.unsafe(helpers).game_notebook_entries_path(@game)
  end
end
