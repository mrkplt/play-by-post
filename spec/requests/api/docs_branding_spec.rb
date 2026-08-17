# typed: false

require "rails_helper"

# The committed openapi/v1/openapi.yaml is brand-neutral (open-source defaults),
# but the served document is rebranded per-request from the deployment's env by
# the rswag swagger_filter (config/initializers/rswag_api.rb). This proves the
# served title and server reflect APP_NAME / APP_HOST, so a deployment
# (flailwhale.com) does not have to regenerate the checked-in file.
RSpec.describe "API docs branding", type: :request do
  around do |example|
    original_name = ENV.fetch("APP_NAME", nil)
    original_host = ENV.fetch("APP_HOST", nil)
    ENV["APP_NAME"] = "flailwhale.com"
    ENV["APP_HOST"] = "flailwhale.com"
    example.run
  ensure
    original_name.nil? ? ENV.delete("APP_NAME") : ENV["APP_NAME"] = original_name
    original_host.nil? ? ENV.delete("APP_HOST") : ENV["APP_HOST"] = original_host
  end

  it "serves the deployment's brand name and server URL" do
    get "/api-docs/v1/openapi.yaml"

    expect(response).to have_http_status(:ok)
    doc = YAML.safe_load(response.body)
    expect(doc["info"]["title"]).to eq("flailwhale.com API")
    expect(doc["servers"]).to eq([ { "url" => "https://flailwhale.com" } ])
  end
end
