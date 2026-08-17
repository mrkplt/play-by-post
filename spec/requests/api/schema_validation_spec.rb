# typed: false

require "rails_helper"

# Proves Api::SchemaValidation (the Rack middleware) is wired: a request whose
# JSON body violates the OpenAPI requestBody schema for an /api path is rejected
# with a 400 and the app's error shape before it reaches the controller. This is
# the live half of "one schema, two consumers" — openapi/v1/openapi.yaml both
# documents the API (Swagger UI) and gates real traffic.
RSpec.describe "API schema validation (Rack middleware)", :db, type: :request do
  let(:game) { create(:game) }
  let(:gm_user) { create(:user, :with_profile) }
  let!(:gm_membership) { create(:game_member, :game_master, game: game, user: gm_user) }
  let(:token) { create(:api_token, user: gm_user, game: game, scope: "api") }
  let(:auth) { { "Authorization" => "Bearer #{token.token}", "Content-Type" => "application/json" } }

  def post_body(payload)
    post "/api/pages", params: payload, headers: auth
  end

  it "rejects a body missing the required `page` object (400, errors shape)" do
    post_body({ not_page: { title: "x" } }.to_json)

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)).to have_key("errors")
  end

  it "rejects a body whose title is the wrong type (400)" do
    post_body({ page: { title: [ 1, 2 ], body: "x" } }.to_json)

    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a body that is not valid JSON (400)" do
    post_body("{ not valid json")

    expect(response).to have_http_status(:bad_request)
  end

  it "lets a schema-valid body through to the controller (201)" do
    post_body({ page: { title: "Valid", body: "# ok" } }.to_json)

    expect(response).to have_http_status(:created)
  end

  it "does not touch a GET (no body to validate)" do
    get "/api/pages", headers: auth

    expect(response).to have_http_status(:ok)
  end
end
