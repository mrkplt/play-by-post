# typed: true

# Base controller for the machine-auth surface: endpoints authenticated by a
# bearer ApiToken rather than a Devise session. Kept a *sibling* of
# ApplicationController (not a subclass) so the two authentication models can
# never accidentally share a session — this controller never touches Warden,
# never sets a session cookie, and reads no session state. Pundit runs with
# `current_data_user` (the token's user) as the authorization subject.
#
# The token is accepted either as a `token` query/body param or an
# `Authorization: Bearer <token>` header. A missing or unknown token is a flat
# 401; per-resource authorization is the concern of each action's `authorize`.
class DataApplicationController < ActionController::Base
  extend T::Sig

  include Pundit::Authorization

  # No CSRF token exists on a token-authenticated request; never fall back to a
  # session to satisfy it.
  protect_from_forgery with: :null_session

  before_action :require_api_token!

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  sig { void }
  def require_api_token!
    head :unauthorized unless current_api_token
  end

  sig { returns(T.nilable(ApiToken)) }
  def current_api_token
    return @current_api_token if defined?(@current_api_token)

    token = bearer_token
    @current_api_token = T.let(
      token.present? ? ApiToken.find_by(token: token) : nil,
      T.nilable(ApiToken)
    )
  end

  sig { returns(T.nilable(User)) }
  def current_data_user
    current_api_token&.user
  end

  # Pundit's authorization subject for this surface.
  sig { returns(T.nilable(User)) }
  def pundit_user
    current_data_user
  end

  sig { returns(T.nilable(String)) }
  def bearer_token
    from_header = request.authorization.to_s[/\ABearer (.+)\z/, 1]
    from_header || params[:token].presence
  end

  sig { params(_error: StandardError).void }
  def forbidden(_error)
    head :forbidden
  end
end
