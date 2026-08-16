require "rails_helper"

RSpec.describe PagesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:removed_player) { create(:user, :with_profile) }
  let(:banned_player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:game_member, :removed, game: game, user: removed_player)
    create(:game_member, :banned, game: game, user: banned_player)
  end

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = get game_page_path(game_id, "x")
  end

  describe "GET show" do
    let!(:page) { create(:page, game: game, title: "Lore", body: "# Lore\n\nContent.") }

    it "renders the rendered markdown for an active member" do
      sign_in(player)
      get game_page_path(game, page)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lore")
    end

    it "shows the version history to the GM" do
      sign_in(gm)
      get game_page_path(game, page)
      expect(response.body).to include("Version History")
    end

    context "when the page is a draft" do
      let!(:page) { create(:page, game: game, title: "Secret draft", body: "hidden", draft: true) }

      it "is visible to the GM who authored it" do
        sign_in(gm)
        get game_page_path(game, page)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Secret draft")
      end

      it "is denied to a player — a draft never leaks through the show route" do
        sign_in(player)
        get game_page_path(game, page)
        expect(response).not_to have_http_status(:ok)
        expect(response.body).not_to include("Secret draft")
      end
    end

    it "does not show the version history to a player" do
      sign_in(player)
      get game_page_path(game, page)
      expect(response.body).not_to include("Version History")
    end

    it "is visible to a removed member" do
      sign_in(removed_player)
      get game_page_path(game, page)
      expect(response).to have_http_status(:ok)
    end

    it "is denied to a banned member" do
      sign_in(banned_player)
      get game_page_path(game, page)
      expect(response).to redirect_to(root_path)
    end

    # The message matters, not just the redirect: without it this passes even
    # if require_game_access! is deleted entirely, since Pundit's own denial
    # also lands on root_path. "Cannot see this game at all" is a distinct
    # outcome from "not allowed to do this particular thing".
    it "is denied to a non-member" do
      sign_in(outsider)
      get game_page_path(game, page)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have access to this game.")
    end

    it "redirects an unauthenticated visitor" do
      get game_page_path(game, page)
      expect(response).to have_http_status(:redirect)
    end

    it "addresses the page by slug, not id" do
      sign_in(player)
      get game_page_path(game, page)
      expect(request.path).to include(page.slug)
    end

    it "renders the universal header nav affordances" do
      sign_in(player)
      get game_page_path(game, page)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Pages")
    end
  end

  describe "GET new" do
    it "is available to the GM" do
      sign_in(gm)
      get new_game_page_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "pre-fills the body from the game's page template when one exists" do
      create(:content_template, game: game, content_type: "page", body: "## Page skeleton")
      sign_in(gm)
      get new_game_page_path(game)
      expect(response.body).to include("## Page skeleton")
    end

    it "leaves the body blank when there is no page template" do
      sign_in(gm)
      get new_game_page_path(game)
      expect(response.body).not_to include("Page skeleton")
    end

    it "is denied to an active player" do
      sign_in(player)
      get new_game_page_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get new_game_page_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Pages")
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get new_game_page_path(game)
      expect(response.body).to include(">Create Page<")
      expect(response.body).to include(">Cancel<")
    end
  end

  describe "POST create" do
    it "creates a page with an auto-generated slug and redirects to it" do
      sign_in(gm)
      expect {
        post game_pages_path(game), params: { page: { title: "New Page", body: "Body" } }
      }.to change(Page, :count).by(1)

      page = Page.last
      expect(page.slug).to match(/\A[a-zA-Z0-9]{16}\z/)
      expect(response).to redirect_to(game_page_path(game, page))

      # Assert the permitted attributes actually landed: the specs sent a body
      # but never checked it persisted, so dropping :body from page_params'
      # permit list changed nothing that a spec could see.
      expect(page.title).to eq("New Page")
      expect(page.body).to eq("Body")
    end

    it "re-renders on validation failure" do
      sign_in(gm)
      expect {
        post game_pages_path(game), params: { page: { title: "", body: "Body" } }
      }.not_to change(Page, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not let an active player create a page" do
      sign_in(player)
      expect {
        post game_pages_path(game), params: { page: { title: "Sneaky", body: "x" } }
      }.not_to change(Page, :count)
    end
  end

  describe "GET edit / PATCH update" do
    let!(:page) { create(:page, game: game, title: "Original") }

    it "lets the GM edit and update" do
      sign_in(gm)
      get edit_game_page_path(game, page)
      expect(response).to have_http_status(:ok)

      patch game_page_path(game, page), params: { page: { title: "Updated" } }
      expect(response).to redirect_to(game_page_path(game, page))
      expect(page.reload.title).to eq("Updated")
    end

    it "keeps the slug stable across an update" do
      sign_in(gm)
      original_slug = page.slug
      patch game_page_path(game, page), params: { page: { title: "Renamed" } }
      expect(page.reload.slug).to eq(original_slug)
    end

    # A Turbo save keeps the writer on the edit screen: the reply is a stream
    # that re-renders the form and the toast in place, not a redirect.
    it "answers a Turbo-driven update with a stream, not a redirect" do
      sign_in(gm)

      patch game_page_path(game, page), params: { page: { title: "Streamed" } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(page.reload.title).to eq("Streamed")
    end

    it "streams the confirmation toast" do
      sign_in(gm)

      patch game_page_path(game, page), params: { page: { title: "Streamed" } }, as: :turbo_stream

      expect(response.body).to include("Page updated.")
      expect(response.body).to include("toast_layer")
    end

    it "streams the form back with its errors when the save fails" do
      sign_in(gm)

      patch game_page_path(game, page), params: { page: { title: "" } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Could not save the page.")
      expect(page.reload.title).to eq("Original")
    end

    it "denies a player" do
      sign_in(player)
      patch game_page_path(game, page), params: { page: { title: "Hacked" } }
      expect(page.reload.title).to eq("Original")
    end

    it "renders the universal header nav affordances on edit" do
      sign_in(gm)
      get edit_game_page_path(game, page)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Pages")
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get edit_game_page_path(game, page)
      expect(response.body).to include(">Save<")
      expect(response.body).to include(">Cancel<")
    end
  end

  describe "DELETE destroy" do
    let!(:page) { create(:page, game: game) }

    it "lets the GM delete a page" do
      sign_in(gm)
      expect {
        delete game_page_path(game, page)
      }.to change(Page, :count).by(-1)
      expect(response).to redirect_to(game_path(game, anchor: "pages"))
    end

    it "denies a player" do
      sign_in(player)
      expect {
        delete game_page_path(game, page)
      }.not_to change(Page, :count)
    end

    it "deletes a promoted page and un-promotes its notebook entry", :db do
      sign_in(gm)
      entry = create(:notebook_entry, game: game, promoted_page: page)

      expect {
        delete game_page_path(game, page)
      }.to change(Page, :count).by(-1)

      expect(response).to redirect_to(game_path(game, anchor: "pages"))
      expect(entry.reload.promoted_page_id).to be_nil
      expect(entry.promoted?).to be(false)
    end
  end
end
