require "rails_helper"

RSpec.describe NotebookEntryVersionsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:entry) { create(:notebook_entry, game: game, title: "Secret", body: "hidden plans") }
  let(:version) { entry.notebook_entry_versions.first! }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET show" do
    it "renders the historical version for the GM" do
      sign_in(gm)
      get game_notebook_entry_notebook_entry_version_path(game, entry, version)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Secret")
    end

    it "addresses the entry by slug" do
      sign_in(gm)
      get game_notebook_entry_notebook_entry_version_path(game, entry, version)

      expect(request.path).to include(entry.slug)
    end

    it "denies a non-GM member — the notebook is GM-only" do
      sign_in(player)
      get game_notebook_entry_notebook_entry_version_path(game, entry, version)

      expect(response).not_to have_http_status(:ok)
      expect(response.body).not_to include("hidden plans")
    end

    it "denies a non-member" do
      sign_in(outsider)
      get game_notebook_entry_notebook_entry_version_path(game, entry, version)

      expect(response).not_to have_http_status(:ok)
    end

    it "redirects an unauthenticated visitor" do
      get game_notebook_entry_notebook_entry_version_path(game, entry, version)

      expect(response).to have_http_status(:redirect)
    end
  end
end
