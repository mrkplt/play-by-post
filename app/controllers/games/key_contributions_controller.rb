# typed: strict

module Games
  # A member offering or revoking THEIR OWN OpenRouter key as a funding source
  # for a game's game-level AI features (GameKeyAuthorization). Consent is the
  # key owner's, so both actions operate on the current user's own row — the
  # policy enforces "own record, and a member of this game".
  class KeyContributionsController < ApplicationController
    extend T::Sig
    include InPlaceRender

    after_action :verify_authorized

    sig { void }
    def create
      authorization = GameKeyAuthorization.new(game: game, user: current_user, feature: feature_param)
      authorize authorization, :create?

      authorization.save
      render_in_place(contribution_notice(authorization))
    end

    sig { void }
    def destroy
      authorization = GameKeyAuthorization.find_by!(game: game, user: current_user, feature: feature_param)
      authorize authorization, :destroy?

      authorization.destroy
      render_in_place("Key contribution removed.")
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

    # The funding toggle lives on the profile among the per-game controls, so a
    # flip re-renders that #game_controls section in place (its funding rows
    # follow the change) plus a toast — no full profile reload. flash.now, not
    # flash: nothing redirects here. Mirrors ByokKeyStreams#game_controls.
    sig { params(notice: String).void }
    def render_in_place(notice)
      flash.now[:notice] = notice
      render turbo_stream: [ game_controls_stream(current_user), toast_stream ]
    end

    sig { params(authorization: GameKeyAuthorization).returns(String) }
    def contribution_notice(authorization)
      return "Key contribution saved." if authorization.persisted?

      authorization.errors.full_messages.to_sentence.presence || "Could not save key contribution."
    end
  end
end
