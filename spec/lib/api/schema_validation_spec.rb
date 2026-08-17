# typed: false

require "rails_helper"
require "api/schema_validation"

# Unit coverage for the Rack middleware, driving it directly with a stubbed app
# and an in-memory OpenAPI document (no HTTP, no Rails stack) so mutant can reach
# every branch: document present/absent, method with/without a body operation,
# path template matching, conforming vs violating bodies, malformed JSON.
RSpec.describe Api::SchemaValidation do
  let(:downstream) { ->(_env) { [ 200, {}, [ "ok" ] ] } }
  let(:document) do
    {
      "paths" => {
        "/api/pages" => {
          "post" => {
            "requestBody" => {
              "content" => { "application/json" => { "schema" => { "$ref" => "#/components/schemas/page_input" } } }
            }
          }
        },
        "/api/pages/{slug}" => {
          "patch" => {
            "requestBody" => {
              "content" => { "application/json" => { "schema" => { "$ref" => "#/components/schemas/page_input" } } }
            }
          }
        }
      },
      "components" => {
        "schemas" => {
          "page_input" => {
            "type" => "object",
            "properties" => { "page" => { "type" => "object", "properties" => { "title" => { "type" => "string" } } } },
            "required" => [ "page" ]
          }
        }
      }
    }
  end

  around do |example|
    Tempfile.create([ "openapi", ".yaml" ]) do |file|
      file.write(document.to_yaml)
      file.flush
      @path = file.path
      example.run
    end
  end

  subject(:middleware) { described_class.new(downstream, document_path: @path) }

  def env_for(method, path, body)
    Rack::MockRequest.env_for(path, method: method, input: body, "CONTENT_TYPE" => "application/json")
  end

  def call(method, path, body)
    middleware.call(env_for(method, path, body))
  end

  it "passes a conforming POST body through to the app" do
    status, = call("POST", "/api/pages", { page: { title: "ok" } }.to_json)
    expect(status).to eq(200)
  end

  it "rejects a POST body missing the required object with 400 and an errors shape" do
    status, _headers, body = call("POST", "/api/pages", { nope: {} }.to_json)
    expect(status).to eq(400)
    expect(JSON.parse(body.first)).to have_key("errors")
  end

  it "rejects a POST body whose field is the wrong type" do
    status, = call("POST", "/api/pages", { page: { title: [ 1 ] } }.to_json)
    expect(status).to eq(400)
  end

  it "rejects a body that is not valid JSON" do
    status, _headers, body = call("POST", "/api/pages", "{not json")
    expect(status).to eq(400)
    expect(JSON.parse(body.first)["errors"]).to include(match(/valid JSON/))
  end

  it "ignores a GET (no body method)" do
    status, = call("GET", "/api/pages", "")
    expect(status).to eq(200)
  end

  it "validates a matched templated path that has a requestBody" do
    # /api/pages/{slug} PATCH has a body schema, so a {slug} match reaches
    # validation and a wrong-type title is rejected — this is what proves the
    # {slug} placeholder actually matched a concrete segment.
    status, = call("PATCH", "/api/pages/abc", { page: { title: [ 1 ] } }.to_json)
    expect(status).to eq(400)
  end

  it "ignores an undocumented path" do
    status, = call("POST", "/other", "{}")
    expect(status).to eq(200)
  end

  it "does not match a path with a different segment count" do
    # /api/pages/a/b has more segments than any template, so no operation
    # matches and the body is not validated.
    status, = call("POST", "/api/pages/a/b", { page: { title: 1 } }.to_json)
    expect(status).to eq(200)
  end

  it "does not match a path whose literal segment differs" do
    status, = call("POST", "/api/other", { page: { title: 1 } }.to_json)
    expect(status).to eq(200)
  end

  it "lets a conforming body through on a matched templated path" do
    status, = call("PATCH", "/api/pages/anything-here", { page: { title: "ok" } }.to_json)
    expect(status).to eq(200)
  end

  it "validates nothing when the document is absent" do
    absent = described_class.new(downstream, document_path: "/no/such/openapi.yaml")
    status, = absent.call(env_for("POST", "/api/pages", "garbage"))
    expect(status).to eq(200)
  end

  it "validates nothing during the dummy-secret asset build" do
    ENV["SECRET_KEY_BASE_DUMMY"] = "1"
    guarded = described_class.new(downstream, document_path: @path)
    status, = guarded.call(env_for("POST", "/api/pages", "garbage"))
    expect(status).to eq(200)
  ensure
    ENV.delete("SECRET_KEY_BASE_DUMMY")
  end
end
