class ApplicationController < ActionController::Base
  include Pagy::Backend

  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_user

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    redirect_to root_path, alert: "That could not be found."
  end

  def bad_request
    redirect_to root_path, alert: "Bad request."
  end

  def set_current_user
    Current.user = current_user
  end

end
