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

    # A lane lists oldest-first, so a GM reads a lane in the order they wrote
    # it. Nothing asserted the ordering, so entries_for could drop its `order`
    # entirely and every spec still passed.
    it "lists a lane oldest first" do
      newer = create(:notebook_entry, game: game, title: "Written Second", created_at: 1.hour.ago)
      older = create(:notebook_entry, game: game, title: "Written First", created_at: 3.hours.ago)

      sign_in(gm)
      get game_notebook_entries_path(game)

      expect(response.body.index(older.title)).to be < response.body.index(newer.title)
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
      expect(response).to redirect_to(root_path)
    end

    # Denial is NotebookEntryPolicy's, surfaced by Pundit's rescue rather than
    # a controller guard restating the rule — so the flash is the app-wide one.
    it "denies through the policy, not a controller guard" do
      sign_in(player)
      get game_notebook_entries_path(game)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "is denied to a removed member" do
      sign_in(removed_player)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "is denied to a banned member" do
      sign_in(banned_player)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "is denied to a non-member" do
      sign_in(outsider)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "is denied to the GM of a different game" do
      sign_in(other_gm)
      get game_notebook_entries_path(game)
      expect(response).to redirect_to(root_path)
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
      expect(response).to redirect_to(root_path)
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get new_game_notebook_entry_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Notebook")
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get new_game_notebook_entry_path(game)
      expect(response.body).to include(">Create Entry<")
      expect(response.body).to include(">Cancel<")
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

      # Assert the permitted attributes actually landed: the spec sent a body
      # but never checked it persisted, so dropping :body from the permit list
      # changed nothing a spec could see.
      expect(entry.title).to eq("New Idea")
      expect(entry.body).to eq("Body")
      expect(flash[:notice]).to eq("Entry created.")
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

  describe "GET edit / PATCH update" do
    let!(:entry) { create(:notebook_entry, game: game, title: "Original") }

    it "lets the GM edit and update" do
      sign_in(gm)
      get edit_game_notebook_entry_path(game, entry)
      expect(response).to have_http_status(:ok)

      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "Updated" } }
      expect(response).to redirect_to(edit_game_notebook_entry_path(game, entry))
      expect(entry.reload.title).to eq("Updated")
      expect(flash[:notice]).to eq("Entry updated.")
    end

    it "addresses the entry by slug, not id" do
      sign_in(gm)
      get edit_game_notebook_entry_path(game, entry)
      expect(request.path).to include(entry.slug)
    end

    it "denies the edit screen to a player" do
      sign_in(player)
      get edit_game_notebook_entry_path(game, entry)
      expect(response).to redirect_to(root_path)
    end

    it "keeps the slug stable across an update" do
      sign_in(gm)
      original_slug = entry.slug
      patch game_notebook_entry_path(game, entry), params: { notebook_entry: { title: "Renamed" } }
      expect(entry.reload.slug).to eq(original_slug)
    end

    it "returns to the edit screen after a Turbo-driven update" do
      sign_in(gm)
      patch game_notebook_entry_path(game, entry),
        params: { notebook_entry: { title: "Streamed Update" } },
        as: :turbo_stream
      expect(response).to redirect_to(edit_game_notebook_entry_path(game, entry))
    end

    it "carries the entry's actions on the edit screen" do
      sign_in(gm)
      get edit_game_notebook_entry_path(game, entry)

      expect(response.body).to include("Promote")
      expect(response.body).to include("Delete")
      expect(response.body).to include("notebook_entry[status]")
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

    it "updates the status and replaces both the source and destination lanes" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" } },
        as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(entry.reload.status).to eq("expand")
      expect(response.body).to include("notebook_column_expand")
      expect(response.body).to include("notebook_column_new")
      expect(response.body.scan('action="replace"').size).to eq(2)
    end

    it "leaves the entry in exactly one lane" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" } },
        as: :turbo_stream

      # The source lane is re-rendered empty and the destination carries it —
      # rows are shared markup with no per-entry id, so a stale row in the old
      # lane would leave the entry visible twice. Count row links rather than
      # raw title text, which also appears in each picker's sr-only label.
      row_href = edit_game_notebook_entry_path(game, entry)
      expect(response.body.scan(%r{href="#{Regexp.escape(row_href)}"}).size).to eq(1)
    end

    it "redirects back to the entry when the picker was not on the board" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" }, response_mode: "standalone" },
        as: :turbo_stream

      # Turbo advertises a turbo_stream Accept header for every unsafe request,
      # so the response must be chosen by the parameter, not the format — a
      # lane-swapping stream targets ids that do not exist off the board.
      expect(response).to redirect_to(edit_game_notebook_entry_path(game, entry))
      expect(flash[:notice]).to eq("Entry moved.")
      expect(entry.reload.status).to eq("expand")
    end

    it "still swaps lanes when the picker was on the board" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" }, response_mode: "board" },
        as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("notebook_column_expand")
    end

    it "replaces a single lane when the status does not actually change" do
      sign_in(gm)
      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "new" } },
        as: :turbo_stream

      expect(entry.reload.status).to eq("new")
      expect(response.body.scan('action="replace"').size).to eq(1)
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
      expect(flash[:notice]).to eq("Promoted to a page.")
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
      expect(response).to redirect_to(root_path)
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
      expect(flash[:notice]).to eq("Entry deleted.")
    end

    it "denies a player" do
      sign_in(player)
      expect {
        delete game_notebook_entry_path(game, entry)
      }.not_to change(NotebookEntry, :count)
    end
  end
end
