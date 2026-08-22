# typed: strict

# View model for the profile's "API tokens" section: one ApiTokenRowPresenter
# per game the person belongs to, paired with that person's api-scoped token
# for the game (if any). `@model` is the profile-listing memberships
# (GameMember.for_profile_listing); tokens are indexed ONCE so the rows do no
# per-game query. Parallels KeyContributionsPresenter / the campaign-log
# collection presenter.
class ApiTokensPresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Array[ApiTokenRowPresenter]) }
  def rows
    @model.filter_map do |membership|
      game = membership.game
      next unless game

      ApiTokenRowPresenter.new(game, token: tokens_by_game_id[game.id], urls: @options.fetch(:urls))
    end
  end

  private

  sig { returns(T::Hash[Integer, ApiToken]) }
  def tokens_by_game_id
    @tokens_by_game_id ||= T.let(
      @options.fetch(:user).api_tokens.where(scope: "api").index_by(&:game_id),
      T.nilable(T::Hash[Integer, ApiToken])
    )
  end
end
