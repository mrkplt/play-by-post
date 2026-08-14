# typed: strict

# View model for the games dashboard (GamesController#index): one row per
# active/former membership, each carrying the derived display values the
# card needs (primary character label, active scene count, "can manage",
# "has new activity since last login"). Wraps the memberships so the view
# asks "how many" / "any at all" of the presenter rather than the raw
# relation, and so the per-membership derivation (which used to live in the
# controller as a hash literal) lives in one place.
class GameDashboardPresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[GameMember], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def empty?
    @model.empty?
  end

  # One item presenter per membership, in the order supplied.
  sig { returns(T::Array[GameDashboardItemPresenter]) }
  def items
    @model.map do |membership|
      GameDashboardItemPresenter.new(
        membership,
        current_user: @options.fetch(:current_user),
        can_manage: @options.fetch(:can_manage_by_game_id).fetch(membership.game_id),
        games_with_new_activity: @options.fetch(:games_with_new_activity)
      )
    end
  end
end
