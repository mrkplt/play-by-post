# typed: true

class ApplicationController < ActionController::Base
  extend T::Sig

  include Pagy::Method
  include Pundit::Authorization

  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_user

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  sig { void }
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back fallback_location: root_path
  end

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
    return if policy(game).write_access?

    redirect_to game_path(game), alert: "You no longer have write access to this game."
  end
end
