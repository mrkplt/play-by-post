# typed: strict

# View model for the profile's "fund AI for your games" section: one
# KeyContributionRowPresenter per game the person belongs to, each told which
# features their key already funds there. `@model` is the person's profile-
# listing memberships (GameMember.for_profile_listing); the authorizations are
# grouped ONCE so the rows do no per-game query. A presenter composing
# presenters — parallels SceneSummaryCollectionPresenter.
class KeyContributionsPresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Array[KeyContributionRowPresenter]) }
  def rows
    @model.filter_map do |membership|
      game = membership.game
      next unless game

      KeyContributionRowPresenter.new(game, contributed_features: contributed_for(game.id), urls: @options.fetch(:urls))
    end
  end

  private

  sig { returns(T::Hash[Integer, T::Array[GameKeyAuthorization]]) }
  def features_by_game
    @features_by_game ||= T.let(
      @options.fetch(:user).game_key_authorizations.group_by(&:game_id),
      T.nilable(T::Hash[Integer, T::Array[GameKeyAuthorization]])
    )
  end

  sig { params(game_id: Integer).returns(T::Set[String]) }
  def contributed_for(game_id)
    (features_by_game[game_id] || []).map(&:feature).to_set
  end
end
