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

  describe "GET /api/notebook_entries filtering and ordering" do
    let(:other_gm) { create(:user, :with_profile) }
    let!(:other_gm_membership) { create(:game_member, :game_master, game: game, user: other_gm) }

    it "filters by a case-insensitive title substring" do
      create(:notebook_entry, game: game, title: "The Heist", editor: gm)
      create(:notebook_entry, game: game, title: "A Quiet Day", editor: gm)

      get "/api/notebook_entries", params: { title: "heist" }, headers: auth(gm_token)

      expect(json.map { |e| e["title"] }).to contain_exactly("The Heist")
    end

    it "filters by created_by to the id of the user who created the entry" do
      mine = create(:notebook_entry, game: game, title: "Mine", editor: gm)
      create(:notebook_entry, game: game, title: "Theirs", editor: other_gm)

      get "/api/notebook_entries", params: { created_by: gm.id }, headers: auth(gm_token)

      slugs = json.map { |e| e["slug"] }
      expect(slugs).to include(mine.slug)
      expect(json.map { |e| e["title"] }).not_to include("Theirs")
    end

    it "created_by does not match a user who only edited an entry they did not create" do
      created = create(:notebook_entry, game: game, title: "Origin", editor: gm)
      Current.user = other_gm
      created.update!(body: "edited by other")
      Current.user = nil

      get "/api/notebook_entries", params: { created_by: other_gm.id }, headers: auth(gm_token)

      expect(json.map { |e| e["slug"] }).not_to include(created.slug)
    end

    it "edited_by matches an entry the user edited even though they did not create it" do
      created = create(:notebook_entry, game: game, title: "Origin", editor: gm)
      Current.user = other_gm
      created.update!(body: "edited by other")
      Current.user = nil

      get "/api/notebook_entries", params: { edited_by: other_gm.id }, headers: auth(gm_token)

      expect(json.map { |e| e["slug"] }).to include(created.slug)
    end

    it "exposes created_by_id (immutable) and edited_by_id (latest editor)" do
      created = create(:notebook_entry, game: game, title: "Attributed", editor: gm)
      Current.user = other_gm
      created.update!(body: "revised")
      Current.user = nil

      get "/api/notebook_entries", params: { title: "Attributed" }, headers: auth(gm_token)

      row = json.find { |e| e["slug"] == created.slug }
      expect(row).to include("created_by_id" => gm.id, "edited_by_id" => other_gm.id)
    end

    it "keeps only entries created at or after `since`" do
      old_entry = Timecop.freeze(3.days.ago) { create(:notebook_entry, game: game, title: "Old", editor: gm) }
      new_entry = create(:notebook_entry, game: game, title: "New", editor: gm)

      get "/api/notebook_entries", params: { since: 1.day.ago.iso8601 }, headers: auth(gm_token)

      slugs = json.map { |e| e["slug"] }
      expect(slugs).to include(new_entry.slug)
      expect(slugs).not_to include(old_entry.slug)
    end

    it "orders newest-first by default and oldest-first on request" do
      first = Timecop.freeze(2.days.ago) { create(:notebook_entry, game: game, title: "First", editor: gm) }
      last = create(:notebook_entry, game: game, title: "Last", editor: gm)

      get "/api/notebook_entries", params: { order: "oldest" }, headers: auth(gm_token)
      oldest_first = json.map { |e| e["slug"] }
      expect(oldest_first.index(first.slug)).to be < oldest_first.index(last.slug)

      get "/api/notebook_entries", params: { order: "newest" }, headers: auth(gm_token)
      newest_first = json.map { |e| e["slug"] }
      expect(newest_first.index(last.slug)).to be < newest_first.index(first.slug)
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
