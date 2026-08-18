# typed: true

# Base controller for the JSON data API (the /api surface Hermes drives). A
# DataApplicationController subclass, so it inherits bearer-ApiToken auth with no
# session: the token carries the game, so no game id appears in any path.
#
# Two things every API action needs and this base supplies:
#   1. Current.user is set to the token's user, so writes to versioned records
#      (Page, NotebookEntry) attribute their snapshots to the acting user — the
#      RSS surface never needs this, but the write API does.
#   2. A uniform JSON error shape: 401 (no/unknown token, from the parent), 403
#      (Pundit), 404 (unknown slug), 422 (validation) — matching the app's
#      existing JSON controllers (posts/drafts, draftable).
module Api
  class BaseController < DataApplicationController
    extend T::Sig

    # require_api_token! (401 on missing/unknown token) is inherited from
    # DataApplicationController; set_current_user runs after it so the token is
    # known before we assign Current.user.
    before_action :set_current_user
    after_action :verify_authorized

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActionController::BadRequest, with: :bad_request

    private

    # The /api surface accepts the token *only* as an `Authorization: Bearer`
    # header — never a query or body param. A URL-embedded token leaks into
    # logs, proxies, and browser history; the RSS feed tolerates that param
    # because a feed reader cannot send a header, but a machine API client can
    # and must. This narrows the base's header-or-param acceptance to
    # header-only for /api.
    sig { returns(T.nilable(String)) }
    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/i, 1]
    end

    # The game every API request operates within: the token carries it, so the
    # controllers scope all lookups through here rather than a path param.
    sig { returns(Game) }
    def current_game
      T.must(T.must(current_api_token).game)
    end

    sig { void }
    def set_current_user
      Current.user = current_data_user
    end

    sig { params(record: ActiveRecord::Base).void }
    def render_errors(record)
      render json: { errors: record.errors.full_messages }, status: :unprocessable_content
    end

    sig { params(_error: ActiveRecord::RecordNotFound).void }
    def not_found(_error)
      render json: { errors: [ "Not found" ] }, status: :not_found
    end

    # A malformed request the controller could not act on — currently only an
    # out-of-range notebook status reaching NotebookLaneMove directly (the schema
    # middleware rejects a documented-enum violation with its own uniform 400
    # first). Rendered in the same { errors: [...] } shape as every other API
    # error so the response is never a bare 400 or a 500.
    sig { params(error: ActionController::BadRequest).void }
    def bad_request(error)
      render json: { errors: [ error.message ] }, status: :bad_request
    end
  end
end
