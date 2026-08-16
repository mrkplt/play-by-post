# typed: false

require "rails_helper"

# Behaviour-level request specs for the pages API, separate from the rswag
# doc-generating spec (pages_spec.rb). The rswag `run_test!` cases assert status
# codes and schema shape — enough for the OpenAPI document, but they leave the
# controller's actual behaviour (which record, which body, which side effect)
# under-asserted. These plain specs assert response bodies and side effects so
# the controller logic is genuinely covered.
RSpec.describe Api::PagesController, :db, type: :request do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let!(:gm_membership) { create(:game_member, :game_master, game: game, user: gm) }
  let(:member) { create(:user, :with_profile) }
  let!(:member_membership) { create(:game_member, game: game, user: member) }
  let(:gm_token) { create(:api_token, user: gm, game: game, scope: "api") }
  let(:member_token) { create(:api_token, user: member, game: game, scope: "api") }

  let!(:published) { create(:page, game: game, title: "Lore", body: "the tale", editor: gm) }
  let!(:draft) { create(:page, game: game, title: "WIP", body: "secret", draft: true, editor: gm) }

  def auth(token) = { "Authorization" => "Bearer #{token.token}" }
  def json = JSON.parse(response.body)

  describe "GET /api/pages" do
    it "returns published pages with slug/title/raw-markdown body for a member" do
      get "/api/pages", headers: auth(member_token)

      expect(response).to have_http_status(:ok)
      lore = json.find { |p| p["slug"] == published.slug }
      expect(lore).to include("title" => "Lore", "body" => "the tale")
      expect(json.map { |p| p["slug"] }).not_to include(draft.slug)
    end

    it "includes the GM's own drafts for the GM" do
      get "/api/pages", headers: auth(gm_token)
      expect(json.map { |p| p["slug"] }).to include(published.slug, draft.slug)
    end
  end

  describe "GET /api/pages/:slug" do
    it "returns the requested page's fields" do
      get "/api/pages/#{published.slug}", headers: auth(member_token)
      expect(response).to have_http_status(:ok)
      expect(json).to include("slug" => published.slug, "title" => "Lore", "body" => "the tale")
    end

    it "404s an unknown slug" do
      get "/api/pages/nope", headers: auth(member_token)
      expect(response).to have_http_status(:not_found)
    end

    it "denies a non-GM member a draft page" do
      get "/api/pages/#{draft.slug}", headers: auth(member_token)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/pages" do
    it "creates a page attributed to the token's user and returns it" do
      expect {
        post "/api/pages", params: { page: { title: "New", body: "# body" } }.to_json,
          headers: auth(gm_token).merge("Content-Type" => "application/json")
      }.to change(Page, :count).by(1)

      expect(response).to have_http_status(:created)
      created = Page.find_by!(slug: json["slug"])
      expect(created.title).to eq("New")
      expect(created.page_versions.last.edited_by_id).to eq(gm.id)
    end

    it "422s a blank title with the errors shape" do
      post "/api/pages", params: { page: { title: "", body: "x" } }.to_json,
        headers: auth(gm_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to have_key("errors")
    end

    it "forbids a non-GM member from creating" do
      post "/api/pages", params: { page: { title: "X", body: "y" } }.to_json,
        headers: auth(member_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/pages/:slug" do
    it "updates the page and snapshots a version attributed to the editor" do
      patch "/api/pages/#{published.slug}", params: { page: { body: "rewritten" } }.to_json,
        headers: auth(gm_token).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(published.reload.body).to eq("rewritten")
      expect(published.page_versions.last.edited_by_id).to eq(gm.id)
    end

    it "forbids a non-GM member from updating" do
      patch "/api/pages/#{published.slug}", params: { page: { body: "x" } }.to_json,
        headers: auth(member_token).merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "401s without a token" do
    get "/api/pages"
    expect(response).to have_http_status(:unauthorized)
  end
end
