require "rails_helper"

RSpec.describe PageVersionsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:page_record) { create(:page, game: game, title: "Lore", body: "the tale") }
  let(:version) { page_record.page_versions.first! }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET show" do
    it "renders the historical version for a member" do
      sign_in(gm)
      get game_page_page_version_path(game, page_record, version)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lore")
    end

    it "is available to a player (version history follows game access)" do
      sign_in(player)
      get game_page_page_version_path(game, page_record, version)

      expect(response).to have_http_status(:ok)
    end

    it "denies a non-member" do
      sign_in(outsider)
      get game_page_page_version_path(game, page_record, version)

      expect(response).to redirect_to(root_path)
    end

    it "addresses the page by slug" do
      sign_in(gm)
      get game_page_page_version_path(game, page_record, version)

      expect(request.path).to include(page_record.slug)
    end

    context "when the page is a draft" do
      let(:page_record) { create(:page, game: game, title: "Draft lore", body: "hidden", draft: true) }

      it "is visible to the GM who authored it" do
        sign_in(gm)
        get game_page_page_version_path(game, page_record, version)

        expect(response).to have_http_status(:ok)
      end

      it "is denied to a player — draft content never leaks via the version endpoint" do
        sign_in(player)
        get game_page_page_version_path(game, page_record, version)

        expect(response).not_to have_http_status(:ok)
        expect(response.body).not_to include("Draft lore")
      end
    end
  end
end
