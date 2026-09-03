# typed: false

require "rails_helper"

# Ai::HttpConnection builds the shared Faraday connection for the AI HTTP
# services. Driven against the test adapter so the real middleware stack (bearer
# auth, JSON parse, raise_error) is exercised.
RSpec.describe Ai::HttpConnection do
  let(:stubs) { "Faraday::Adapter::Test::Stubs".constantize.new }

  def connection
    described_class.build(api_key: "secret", timeout: 30, adapter: [ :test, stubs ])
  end

  it "sends a bearer authorization header" do
    captured = {}
    stubs.get("/probe") do |env|
      captured[:authorization] = env.request_headers["Authorization"]
      [ 200, { "Content-Type" => "application/json" }, JSON.generate("ok" => true) ]
    end

    connection.get("/probe")

    expect(captured[:authorization]).to eq("Bearer secret")
  end

  it "parses a JSON response body into a Hash" do
    stubs.get("/probe") { |_env| [ 200, { "Content-Type" => "application/json" }, JSON.generate("a" => 1) ] }

    expect(connection.get("/probe").body).to eq("a" => 1)
  end

  it "raises on an error status (raise_error middleware)" do
    stubs.get("/probe") { |_env| [ 500, {}, "boom" ] }

    expect { connection.get("/probe") }.to raise_error(Faraday::Error)
  end

  it "applies the given timeout" do
    expect(connection.options.timeout).to eq(30)
    expect(connection.options.open_timeout).to eq(10)
  end
end
