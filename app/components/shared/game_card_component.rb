# typed: strict

# A dashboard game card. Shows the game name (with a GM crown when the viewer
# is GM), the player's primary character (+N), and either an active-scene count
# or, for a former/removed game, a moon + "Not currently active". Former cards
# take the blue dormant tint. Cards with new activity get the persistent
# attention glow (.is-hot); every card gets the hover-glow affordance.
class Shared::GameCardComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: Game,
      can_manage: T::Boolean,
      former: T::Boolean,
      character_label: T.nilable(String),
      active_scene_count: Integer,
      new_activity: T::Boolean
    ).void
  end
  def initialize(game:, can_manage:, former:, character_label:, active_scene_count:, new_activity: false)
    @game = game
    @can_manage = can_manage
    @former = former
    @character_label = character_label
    @active_scene_count = active_scene_count
    @new_activity = new_activity
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Boolean) }
  def show_crown?
    @can_manage
  end

  sig { returns(T::Boolean) }
  def former?
    @former
  end

  sig { returns(T.nilable(String)) }
  attr_reader :character_label

  sig { returns(T::Boolean) }
  def new_activity?
    @new_activity
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def link_data
    @new_activity ? { new_activity: true } : {}
  end

  sig { returns(String) }
  def card_classes
    base = "attn-item block relative rounded-card p-[14px_16px] flex flex-col gap-1.5 no-underline"
    tint = former? ? "bg-tint-blue-bg border border-tint-blue-border opacity-85" : "bg-card border border-card-border"
    hot = @new_activity ? "is-hot" : ""
    [ base, tint, hot ].reject(&:empty?).join(" ")
  end

  sig { returns(String) }
  def name_classes
    former? ? "font-bold text-[15px] text-tint-blue-strong" : "font-bold text-[15px] text-ink"
  end

  sig { returns(String) }
  def character_classes
    former? ? "text-[13px] text-tint-blue-soft" : "text-[13px] text-row-ink"
  end

  sig { returns(String) }
  def meta_classes
    former? ? "text-[11px] text-tint-blue-soft" : "text-[11px] text-muted"
  end

  # The bottom meta line: scene count for an active game, dormant note for a
  # former one.
  sig { returns(String) }
  def meta_text
    return "Not currently active" if former?

    "#{@active_scene_count} active #{@active_scene_count == 1 ? 'scene' : 'scenes'}"
  end
end
