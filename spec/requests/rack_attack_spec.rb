require "rails_helper"

# rack-attack is off in test; enable it and use a fresh MemoryStore per example
# (restored after) so counters accumulate without leaking across examples.
RSpec.describe "rack-attack throttling", type: :request do
  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.enabled = original_enabled
    Rack::Attack.cache.store = original_store
    Rack::Attack.reset!
  end

  describe "magic-link sign-in POST /users/sign_in" do
    it "allows requests up to the per-IP limit then throttles" do
      # Limit is 10/3min per IP. Vary email so the per-email limit (5) isn't the
      # one that trips first.
      10.times do |i|
        post user_session_path, params: { user: { email: "user#{i}@example.com" } }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      post user_session_path, params: { user: { email: "user11@example.com" } }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "throttles by normalized email regardless of case/whitespace" do
      # Limit is 5/3min per email. Same address in varied forms shares a bucket.
      5.times do
        post user_session_path, params: { user: { email: "  Repeat@Example.COM " } }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      post user_session_path, params: { user: { email: "repeat@example.com" } }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "does not share a bucket across different IPs" do
      # Exhaust the per-IP limit from one IP...
      11.times do |i|
        post user_session_path, params: { user: { email: "a#{i}@example.com" } },
             headers: { "REMOTE_ADDR" => "10.0.0.1" }
      end
      # ...a different IP is unaffected.
      post user_session_path, params: { user: { email: "fresh@example.com" } },
           headers: { "REMOTE_ADDR" => "10.0.0.2" }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "sets a Retry-After header on the throttled response" do
      11.times { |i| post user_session_path, params: { user: { email: "b#{i}@example.com" } } }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers["retry-after"]).to be_present
    end
  end

  describe "invitation accept GET /invitations/:token/accept" do
    it "throttles by IP after the limit" do
      # Limit is 20/min per IP; use distinct invalid tokens so the per-token
      # limit (10) isn't the tripwire.
      20.times { |i| get "/invitations/token-#{i}/accept" }
      get "/invitations/token-final/accept"
      expect(response).to have_http_status(:too_many_requests)
    end

    it "throttles a single token being hammered" do
      # Limit is 10/min per token.
      10.times { get "/invitations/guess-me/accept" }
      get "/invitations/guess-me/accept"
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "inbound email webhook POST /mail/inbound" do
    it "throttles by IP after the tighter limit" do
      # Limit is 30/min per IP. These fail signature verification (401) but still
      # count toward the throttle, which is the point — a flood is capped.
      30.times { post "/mail/inbound" }
      post "/mail/inbound"
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "when disabled (default test configuration)" do
    it "does not throttle" do
      Rack::Attack.enabled = false
      50.times { post user_session_path, params: { user: { email: "flood@example.com" } } }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
