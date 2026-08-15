# typed: strict
# frozen_string_literal: true

# Pundit's `policy` arrives as a callable so authorization stays the
# controller's to resolve (R2).
class GameDashboardQuery
  extend T::Sig

  sig { params(user: User, policies: T.untyped).void }
  def initialize(user, policies)
    @user = user
    @policies = policies
  end

  sig { returns(GameDashboardPresenter) }
  def presenter
    GameDashboardPresenter.new(
      memberships,
      current_user: @user,
      policy_by_game_id: policy_by_game_id,
      games_with_new_activity: games_with_new_activity
    )
  end

  # `where(game_id: Game.all)` drops soft-deleted games: the default scope makes
  # membership.game nil for those, and a nil must not reach the dashboard loop.
  sig { returns(T::Array[GameMember]) }
  def memberships
    @memberships ||= T.let(
      @user.game_members
        .where.not(status: "banned")
        .where(game_id: Game.all)
        .includes(game: %i[scenes])
        .order("games.name")
        .to_a,
      T.nilable(T::Array[GameMember])
    )
  end

  # One policy per game, shared with the GamePresenter each dashboard item
  # wraps, so a card's crown and its "can_manage" flag can never disagree.
  sig { returns(T::Hash[Integer, GamePolicy]) }
  def policy_by_game_id
    memberships.each_with_object({}) do |membership, hash|
      game = membership.game
      next if game.nil?

      hash[game.id] = @policies.call(game)
    end
  end

  # Drives the dashboard card's "new activity" glow.
  sig { returns(T::Array[Integer]) }
  def games_with_new_activity
    last_login_at = @user.user_profile&.last_login_at
    game_ids = memberships.filter_map(&:game_id)
    return [] unless last_login_at && game_ids.any?

    Post.joins(:scene)
      .where(scenes: { game_id: game_ids })
      .where("posts.created_at > ?", last_login_at)
      .distinct
      .pluck("scenes.game_id")
  end
end
