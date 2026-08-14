# typed: strict

# One row of the games dashboard: a membership plus the derived values
# Shared::GameCardComponent needs. `can_manage` arrives precomputed
# (options[:can_manage]) because it is a per-game Pundit answer the
# controller already holds via `policy(game)` — the presenter never builds
# a policy itself (R2).
class GameDashboardItemPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameMember, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(Game) }
  def game
    @model.game
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:can_manage)
  end

  sig { returns(T::Boolean) }
  def former?
    @model.removed?
  end

  # "Vex Marrowgate +1" — primary character plus a count of the rest, or nil
  # when the viewer has no character in this game.
  sig { returns(T.nilable(String)) }
  def character_label
    characters = user_characters
    primary = characters.first
    return nil if primary.nil?

    extra = characters.length - 1
    extra.positive? ? "#{primary.name} +#{extra}" : primary.name
  end

  sig { returns(Integer) }
  def active_scene_count
    game.scenes.where(resolved_at: nil).count
  end

  sig { returns(T::Boolean) }
  def new_activity?
    @options.fetch(:games_with_new_activity).include?(game.id)
  end

  private

  sig { returns(T::Array[Character]) }
  def user_characters
    game.characters.active.where(user: @options.fetch(:current_user)).to_a
  end
end
