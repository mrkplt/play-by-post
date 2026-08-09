require "rails_helper"

RSpec.describe NotebookEntriesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:removed_player) { create(:user, :with_profile) }
  let(:banned_player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:other_gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:other_game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:game_member, :removed, game: game, user: removed_player)
    create(:game_member, :banned, game: game, user: banned_player)
    create(:game_member, :game_master, game: other_game, user: other_gm)
  end

  describe "GET index" do
    let!(:entry) { create(:notebook_entry, game: game, title: "Idea") }

    it "renders entries for the GM" do
      sign_in(gm)
      get game_notebook_entries_path(game)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Idea")
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get game_notebook_entries_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Notebook")
    end

    it "is denied to an active player" do
      sign_in(player)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "is denied to a removed member" do
      sign_in(removed_player)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "is denied to a banned member" do
      sign_in(banned_player)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "is denied to a non-member" do
      sign_in(outsider)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "is denied to the GM of a different game" do
      sign_in(other_gm)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "redirects an unauthenticated visitor" do
      get game_notebook_entries_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET new" do
    it "is available to the GM" do
      sign_in(gm)
      get new_game_notebook_entry_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "is denied to an active player" do
      sign_in(player)
      get new_game_notebook_entry_path(game)
      expect(response).to redirect_to(game_path(game))
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get new_game_notebook_entry_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Notebook")
    end
  end

  describe "POST create" do
    it "creates an entry with an auto-generated slug and status new" do
      sign_in(gm)
      expect {
        post game_notebook_entries_path(game), params: { notebook_entry: { title: "New Idea", body: "Body" } }
      }.to change(NotebookEntry, :count).by(1)

      entry = NotebookEntry.last
      expect(entry.slug).to match(/\A[a-zA-Z0-9]{16}\z/)
      expect(entry.status).to eq("new")
      expect(response).to redirect_to(game_notebook_entries_path(game))
    end

    it "re-renders on validation failure" do
      sign_in(gm)
      expect {
        post game_notebook_entries_path(game), params: { notebook_entry: { title: "", body: "Body" } }
      }.not_to change(NotebookEntry, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "redirects to the index even when Turbo requests turbo_stream" do
      sign_in(gm)
      post game_notebook_entries_path(game),
        params: { notebook_entry: { title: "Streamed", body: "x" } },
        as: :turbo_stream
      expect(response).to redirect_to(game_notebook_entries_path(game))
    end

    it "does not let an active player create an entry" do
      sign_in(player)
      expect {
        post game_notebook_entries_path(game), params: { notebook_entry: { title: "Sneaky", body: "x" } }
      }.not_to change(NotebookEntry, :count)
    end
  end

  describe "GET show" do
    let!(:entry) { create(:notebook_entry, game: game, title: "Lore") }

    it "is visible to the GM" do
      sign_in(gm)
      get game_notebook_entry_path(game, entry)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lore")
    end

    it "is denied to a player" do
      sign_in(player)
      get game_notebook_entry_path(game, entry)
      expect(response).to redirect_to(game_path(game))
    end

    it "addresses the entry by slug, not id" do
      sign_in(gm)
      get game_notebook_entry_path(game, entry)
      expect(request.path).to include(entry.slug)
    end
  end

  describe "GET edit / PATCH update" do
    let!(:entry) { create(:notebook_entry, game: game, title: "Original") }

    it "lets the GM edit and update" do
      sign_in(gm)
      get edit_game_notebook_entry_path(game, entry)
      expect(response).to have_http_status(:ok)

      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "Updated" } }
      expect(response).to redirect_to(game_notebook_entry_path(game, entry))
      expect(entry.reload.title).to eq("Updated")
    end

    it "keeps the slug stable across an update" do
      sign_in(gm)
      original_slug = entry.slug
      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "Renamed" } }
      expect(entry.reload.slug).to eq(original_slug)
    end

    it "responds with a turbo_stream replacing the card in read mode for an inline (board) edit" do
      sign_in(gm)
      patch game_notebook_entry_path(game, entry),
        params: { notebook_entry: { title: "Streamed Update" }, inline: "1" },
        as: :turbo_stream
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("Streamed Update")
    end

    it "redirects to show for a non-inline edit even when Turbo requests turbo_stream" do
      sign_in(gm)
      patch game_notebook_entry_path(game, entry),
        params: { notebook_entry: { title: "Streamed Update" } },
        as: :turbo_stream
      expect(response).to redirect_to(game_notebook_entry_path(game, entry))
    end

    it "edit responds with a turbo_stream replacing the card in edit mode" do
      sign_in(gm)
      get edit_game_notebook_entry_path(game, entry), as: :turbo_stream
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("textarea")
    end

    it "does not permit setting status via update" do
      sign_in(gm)
      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "x", status: "discard" } }
      expect(entry.reload.status).to eq("new")
    end

    it "denies a player" do
      sign_in(player)
      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "Hacked" } }
      expect(entry.reload.title).to eq("Original")
    end
  end

  describe "PATCH move" do
    let!(:entry) { create(:notebook_entry, game: game, status: "new") }

    it "updates the status and responds with a turbo_stream moving the card" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" } },
        as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(entry.reload.status).to eq("expand")
      expect(response.body).to include("notebook_column_expand")
      expect(response.body).to include("turbo-stream action=\"remove\"")
    end

    it "rejects an invalid status" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "bogus" } },
        as: :turbo_stream
      expect(entry.reload.status).to eq("new")
    end

    it "does not permit updating title/body via move" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand", title: "Hacked" } },
        as: :turbo_stream
      expect(entry.reload.title).not_to eq("Hacked")
    end

    it "denies a player" do
      sign_in(player)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" } },
        as: :turbo_stream
      expect(entry.reload.status).to eq("new")
    end
  end

  describe "POST promote" do
    let!(:entry) { create(:notebook_entry, game: game, title: "Promote Me", body: "Body content") }

    it "creates a page and marks the entry as promoted (html)" do
      sign_in(gm)
      expect {
        post promote_game_notebook_entry_path(game, entry)
      }.to change(Page, :count).by(1)

      page = Page.last
      expect(page.title).to eq("Promote Me")
      expect(page.body).to eq("Body content")
      expect(entry.reload.status).to eq("done")
      expect(entry.promoted_page_id).to eq(page.id)
      expect(response).to redirect_to(game_page_path(game, page))
    end

    it "redirects to the promoted page even when Turbo requests turbo_stream" do
      sign_in(gm)
      post promote_game_notebook_entry_path(game, entry), as: :turbo_stream
      page = Page.last
      expect(response).to redirect_to(game_page_path(game, page))
    end

    it "is a no-op on re-promotion — no duplicate page" do
      sign_in(gm)
      post promote_game_notebook_entry_path(game, entry)
      first_page_id = entry.reload.promoted_page_id

      expect {
        post promote_game_notebook_entry_path(game, entry)
      }.not_to change(Page, :count)

      expect(entry.reload.promoted_page_id).to eq(first_page_id)
    end

    it "denies a player" do
      sign_in(player)
      expect {
        post promote_game_notebook_entry_path(game, entry)
      }.not_to change(Page, :count)
    end

    it "denies the GM of a different game" do
      sign_in(other_gm)
      expect {
        post promote_game_notebook_entry_path(game, entry)
      }.not_to change(Page, :count)
      expect(response).to redirect_to(game_path(game))
    end
  end

  describe "DELETE destroy" do
    let!(:entry) { create(:notebook_entry, game: game) }

    it "lets the GM delete an entry" do
      sign_in(gm)
      expect {
        delete game_notebook_entry_path(game, entry)
      }.to change(NotebookEntry, :count).by(-1)
      expect(response).to redirect_to(game_notebook_entries_path(game))
    end

    it "denies a player" do
      sign_in(player)
      expect {
        delete game_notebook_entry_path(game, entry)
      }.not_to change(NotebookEntry, :count)
    end
  end
end
