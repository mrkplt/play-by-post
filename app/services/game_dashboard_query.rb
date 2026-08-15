# typed: strict
# frozen_string_literal: true

# The three reads behind the games dashboard: which memberships to show, the
# policy for each of their games, and which games have activity the viewer has
# not seen. Pundit's `policy` arrives as a callable so authorization stays the
# controller's to resolve (R2).
class GameDashboardQuery
  extend T::Sig

  sig { params(user: User, policies: T.untyped).void }
  def initialize(user, policies)
    @user = user
    @policies = policies
  end

  # The dashboard, ready to render — the controller asks for one thing rather
  # than assembling three reads into a presenter itself.
  sig { returns(GameDashboardPresenter) }
  def presenter
    GameDashboardPresenter.new(
      memberships,
      current_user: @user,
      policy_by_game_id: policy_by_game_id,
      games_with_new_activity: games_with_new_activity
    )
  end

  # Active/former memberships, oldest-game-name first. Memberships whose game
  # was soft-deleted are dropped: the default scope makes membership.game nil
  # for those, so they must not reach the dashboard loop. Game.all carries the
  # default scope, so this is IN (kept game ids).
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

  # Pundit's policy per game, resolved once here (where policies belong)
  # rather than per-item in the presenter. Each GameDashboardItemPresenter
  # wraps its game in a GamePresenter carrying this same policy, so the card's
  # crown and the "can_manage" flag can never disagree.
  sig { returns(T::Hash[Integer, GamePolicy]) }
  def policy_by_game_id
    memberships.each_with_object({}) do |membership, hash|
      game = membership.game
      next if game.nil?

      hash[game.id] = @policies.call(game)
    end
  end

  # Ids of games with a post newer than the viewer's last login — the dashboard
  # card's "new activity" glow.
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
