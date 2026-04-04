# typed: true

class ApplicationController < ActionController::Base
  extend T::Sig

  include Pagy::Method

  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_user

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  sig { void }
  def not_found
    redirect_to root_path, alert: "That could not be found."
  end

  sig { void }
  def bad_request
    redirect_to root_path, alert: "Bad request."
  end

  sig { void }
  def set_current_user
    Current.user = current_user
  end

  sig { params(game: Game).void }
  def require_active_member!(game)
    membership = game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active?

    redirect_to game_path(game), alert: "You no longer have write access to this game."
  end
end
