require "rails_helper"

RSpec.describe NotebookEntries::LanesController, type: :request do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:entry) { create(:notebook_entry, game: game, status: "new") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = patch move_game_notebook_entry_path(game_id, "x")
  end

  describe "PATCH move" do
    it "moves the entry to the requested lane" do
      sign_in gm

      patch move_game_notebook_entry_path(game, entry), params: { notebook_entry: { status: "expand" } }

      expect(entry.reload.status).to eq("expand")
    end

    it "returns to the entry when moved from its own edit screen" do
      sign_in gm

      patch move_game_notebook_entry_path(game, entry),
        params: { notebook_entry: { status: "expand" }, response_mode: "standalone" }

      expect(response).to redirect_to(edit_game_notebook_entry_path(game, entry))
    end

    it "denies a player" do
      sign_in player

      patch move_game_notebook_entry_path(game, entry), params: { notebook_entry: { status: "expand" } }

      expect(entry.reload.status).to eq("new")
    end
  end

  describe "POST promote" do
    it "creates a page from the entry and goes to it" do
      sign_in gm

      expect { post promote_game_notebook_entry_path(game, entry) }.to change { game.pages.count }.by(1)
      expect(response).to redirect_to(game_page_path(game, game.pages.last))
    end

    it "denies a player" do
      sign_in player

      expect { post promote_game_notebook_entry_path(game, entry) }.not_to change { game.pages.count }
    end
  end
end
