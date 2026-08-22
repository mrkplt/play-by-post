# typed: strict

module Games
  # A member offering or revoking THEIR OWN OpenRouter key as a funding source
  # for a game's game-level AI features (GameKeyAuthorization). Consent is the
  # key owner's, so both actions operate on the current user's own row — the
  # policy enforces "own record, and a member of this game".
  class KeyContributionsController < ApplicationController
    extend T::Sig

    after_action :verify_authorized

    sig { void }
    def create
      authorization = GameKeyAuthorization.new(game: game, user: current_user, feature: feature_param)
      authorize authorization, :create?

      authorization.save
      redirect_to redirect_target, notice: contribution_notice(authorization)
    end

    sig { void }
    def destroy
      authorization = GameKeyAuthorization.find_by!(game: game, user: current_user, feature: feature_param)
      authorize authorization, :destroy?

      authorization.destroy
      redirect_to redirect_target, notice: "Key contribution removed."
    end

    private

    sig { returns(Game) }
    def game
      Game.find_by!(slug: params[:game_id])
    end

    sig { returns(String) }
    def feature_param
      params.require(:feature)
    end

    sig { returns(String) }
    def redirect_target
      profile_path
    end

    sig { params(authorization: GameKeyAuthorization).returns(String) }
    def contribution_notice(authorization)
      return "Key contribution saved." if authorization.persisted?

      authorization.errors.full_messages.to_sentence.presence || "Could not save key contribution."
    end
  end
end
