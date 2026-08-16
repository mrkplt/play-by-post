# typed: strict

# A dashboard game card. Shows the game name (with a GM crown when the viewer
# is GM), the player's primary character (+N), and either an active-scene count
# or, for a former/removed game, a moon + "Not currently active". Former cards
# take the blue dormant tint. Cards with new activity get the persistent
# attention glow (.is-hot); every card gets the hover-glow affordance.
#
# Takes the dashboard row presenter directly rather than its fields
# destructured into six parameters — GameDashboardItemPresenter already
# carries game/can_manage?/former?/character_label/active_scene_count/
# new_activity? as one coherent view of "this row", so passing it whole
# avoids re-stating that shape at the call site.
class Shared::GameCardComponent < ApplicationComponent
  extend T::Sig

  CARD_BASE = T.let(
    "attn-item block relative rounded-card p-[14px_16px] flex flex-col gap-1.5 no-underline",
    String
  )

  # Every former?-conditional class string, keyed by former state, so the
  # component branches on former? once per tone rather than repeating the
  # ternary at each class method.
  TONES = T.let({
    former: {
      card_tint: "bg-tint-blue-bg border border-tint-blue-border opacity-85",
      name: "font-bold text-[15px] text-tint-blue-strong",
      character: "text-[13px] text-tint-blue-soft",
      meta: "text-[11px] text-tint-blue-soft"
    },
    active: {
      card_tint: "bg-card border border-card-border",
      name: "font-bold text-[15px] text-ink",
      character: "text-[13px] text-row-ink",
      meta: "text-[11px] text-muted"
    }
  }.freeze, T::Hash[Symbol, T::Hash[Symbol, String]])

  sig { params(item: GameDashboardItemPresenter).void }
  def initialize(item:)
    @item = item
  end

  sig { returns(GamePresenter) }
  def game
    @item.game
  end

  sig { returns(String) }
  def game_path
    helpers.game_path(game)
  end

  sig { returns(T::Boolean) }
  def show_crown?
    @item.can_manage?
  end

  sig { returns(T::Boolean) }
  def former?
    @item.former?
  end

  sig { returns(T.nilable(String)) }
  def character_label
    @item.character_label
  end

  sig { returns(T::Boolean) }
  def new_activity?
    @item.new_activity?
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_data
    new_activity? ? { new_activity: true } : {}
  end

  sig { returns(String) }
  def card_classes
    glow = new_activity? ? "is-hot" : ""
    [ CARD_BASE, tone.fetch(:card_tint), glow ].reject(&:empty?).join(" ")
  end

  sig { returns(String) }
  def name_classes
    tone.fetch(:name)
  end

  sig { returns(String) }
  def character_classes
    tone.fetch(:character)
  end

  sig { returns(String) }
  def meta_classes
    tone.fetch(:meta)
  end

  # The bottom meta line: scene count for an active game, dormant note for a
  # former one.
  sig { returns(String) }
  def meta_text
    return "Not currently active" if former?

    count = @item.active_scene_count
    "#{count} active #{count == 1 ? 'scene' : 'scenes'}"
  end

  private

  sig { returns(T::Hash[Symbol, String]) }
  def tone
    TONES.fetch(former? ? :former : :active)
  end
end
