# typed: strict

# The game secondary nav — instance #1 of Shared::HeaderComponent's
# secondary_nav slot. Wraps Ui::PillTabsComponent with the game section tab
# list (moved from the old Shared::GameHeaderComponent#tabs).
#
# Two modes:
#   :switch — today's client-side panel toggling on games/show (no navigation).
#   :link   — cross-page anchors to each section's own page, active tab
#             marked from the current section.
#
# Takes the game's presenter rather than the model: the nav needs the game's
# id (for routing) and the viewer's manage capability, both of which the
# presenter already exposes — a raw Game would let the component reach past
# that into the model itself.
class Shared::GameNavComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_presenter: GamePresenter, active_tab: Symbol, mode: Symbol).void }
  def initialize(game_presenter:, active_tab:, mode: :switch)
    @game_presenter = game_presenter
    @active_tab = active_tab
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
    base << Ui::PillTabsComponent::Tab.new(label: "Notebook", href: notebook_href, panel: :notebook) if @game_presenter.can_manage?
    base
  end

  private

  sig { returns(String) }
  def scenes_href
    T.unsafe(helpers).game_scenes_path(@game_presenter)
  end

  sig { returns(String) }
  def roster_href
    T.unsafe(helpers).game_path(@game_presenter, anchor: "roster")
  end

  sig { returns(String) }
  def files_href
    T.unsafe(helpers).game_game_files_path(@game_presenter)
  end

  sig { returns(String) }
  def pages_href
    T.unsafe(helpers).game_path(@game_presenter, anchor: "pages")
  end

  sig { returns(String) }
  def links_href
    T.unsafe(helpers).game_game_links_path(@game_presenter)
  end

  sig { returns(String) }
  def notebook_href
    T.unsafe(helpers).game_notebook_entries_path(@game_presenter)
  end
end
