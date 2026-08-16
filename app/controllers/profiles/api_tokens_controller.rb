# typed: true

# Session-authenticated management of the current user's ApiTokens (feed/API
# bearer credentials). Distinct from the machine-auth surface: a user mints and
# revokes their own tokens here, signed in; the tokens are then used against
# DataApplicationController without a session. Kept as a dedicated controller so
# the API's token management can grow here without bloating ProfilesController.
class Profiles::ApiTokensController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  sig { void }
  def create
    authorize current_profile, :manage?

    game = member_game(params[:game_id])
    scope = token_scope
    return redirect_to profile_path, alert: "Could not create a feed token for that game." unless game && scope

    issue_token(game, scope)
  end

  sig { void }
  def destroy
    authorize current_profile, :manage?

    current_user.api_tokens.find_by(id: params[:id])&.destroy
    redirect_to profile_path, notice: "Feed token revoked."
  end

  private

  sig { returns(UserProfile) }
  def current_profile
    current_user.user_profile || current_user.build_user_profile
  end

  sig { params(game: Game, scope: String).void }
  def issue_token(game, scope)
    ApiToken.issue_for!(user: current_user, game: game, scope: scope)
    redirect_to profile_path, notice: "Feed token created."
  end

  # The requested game, but only if the current user is a non-banned member of
  # it — a token must never be mintable for a game the user cannot access.
  sig { params(game_id: T.untyped).returns(T.nilable(Game)) }
  def member_game(game_id)
    current_user.games
      .where.not(game_members: { status: "banned" })
      .find_by(id: game_id)
  end

  sig { returns(T.nilable(String)) }
  def token_scope
    scope = params[:scope].presence || "rss"
    ApiToken::SCOPES.include?(scope) ? scope : nil
  end
end
