# typed: false

require "rails_helper"

# Behaviour-level request specs for the notebook-entries API, separate from the
# rswag doc-generating spec. Describes the controller constant so mutant maps
# these tests to the subject, and asserts response bodies + side effects (the
# rswag `run_test!` cases only assert status/schema).
RSpec.describe Api::NotebookEntriesController, :db, type: :request do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let!(:gm_membership) { create(:game_member, :game_master, game: game, user: gm) }
  let(:member) { create(:user, :with_profile) }
  let!(:member_membership) { create(:game_member, game: game, user: member) }
  let(:gm_token) { create(:api_token, user: gm, game: game, scope: "api") }
  let(:member_token) { create(:api_token, user: member, game: game, scope: "api") }

  let!(:entry) { create(:notebook_entry, game: game, title: "Plan", body: "the scheme", editor: gm) }

  def auth(token) = { "Authorization" => "Bearer #{token.token}" }
  def json = JSON.parse(response.body)

  describe "GET /api/notebook_entries" do
    it "lists the game's entries with slug/title/raw-markdown body/status for the GM" do
      get "/api/notebook_entries", headers: auth(gm_token)

      expect(response).to have_http_status(:ok)
      row = json.find { |e| e["slug"] == entry.slug }
      expect(row).to include("title" => "Plan", "body" => "the scheme", "status" => "new")
    end

    it "forbids a non-GM member" do
      get "/api/notebook_entries", headers: auth(member_token)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/notebook_entries/:slug" do
    it "returns the entry's fields for the GM" do
      get "/api/notebook_entries/#{entry.slug}", headers: auth(gm_token)
      expect(response).to have_http_status(:ok)
      expect(json).to include("slug" => entry.slug, "title" => "Plan", "body" => "the scheme")
    end

    it "404s an unknown slug" do
      get "/api/notebook_entries/nope", headers: auth(gm_token)
      expect(response).to have_http_status(:not_found)
    end

    it "forbids a non-GM member" do
      get "/api/notebook_entries/#{entry.slug}", headers: auth(member_token)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/notebook_entries" do
    it "creates an entry attributed to the token's user and returns it" do
      expect {
        post "/api/notebook_entries", params: { notebook_entry: { title: "New", body: "# body" } }.to_json,
          headers: auth(gm_token).merge("Content-Type" => "application/json")
      }.to change(NotebookEntry, :count).by(1)

      expect(response).to have_http_status(:created)
      created = NotebookEntry.find_by!(slug: json["slug"])
      expect(created.title).to eq("New")
      expect(created.notebook_entry_versions.last.edited_by_id).to eq(gm.id)
    end

    it "422s a blank title with the errors shape" do
      post "/api/notebook_entries", params: { notebook_entry: { title: "", body: "x" } }.to_json,
        headers: auth(gm_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to have_key("errors")
    end

    it "forbids a non-GM member from creating" do
      post "/api/notebook_entries", params: { notebook_entry: { title: "X", body: "y" } }.to_json,
        headers: auth(member_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/notebook_entries/:slug" do
    it "updates the entry and snapshots a version attributed to the editor" do
      patch "/api/notebook_entries/#{entry.slug}", params: { notebook_entry: { body: "rewritten" } }.to_json,
        headers: auth(gm_token).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(entry.reload.body).to eq("rewritten")
      expect(entry.notebook_entry_versions.last.edited_by_id).to eq(gm.id)
    end

    it "forbids a non-GM member from updating" do
      patch "/api/notebook_entries/#{entry.slug}", params: { notebook_entry: { body: "x" } }.to_json,
        headers: auth(member_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "401s without a token" do
    get "/api/notebook_entries"
    expect(response).to have_http_status(:unauthorized)
  end
end
