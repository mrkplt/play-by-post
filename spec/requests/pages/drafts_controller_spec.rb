require "rails_helper"

# Pages::DraftsController is the page-specific adopter of Draftable::Controller:
# it wires the save/publish actions to the shared helpers and supplies the
# page lookup, permitted params, redirect target, and access guard. The shared
# save/publish behaviour itself is exercised in spec/requests/draftable/
# controller_spec.rb; this spec pins the page-specific wiring.
RSpec.describe Pages::DraftsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let!(:page) { create(:page, game: game, title: "Draft", body: "old") }

  before { create(:game_member, :game_master, game: game, user: gm) }

  describe "PATCH save" do
    it "autosaves the page as a draft with the submitted body" do
      sign_in(gm)

      patch save_draft_game_page_path(game, page),
            params: { page: { title: "Draft", body: "new body" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(page.reload.draft).to be(true)
      expect(page.body).to eq("new body")
    end

    it "denies a non-member" do
      sign_in(outsider)

      patch save_draft_game_page_path(game, page),
            params: { page: { body: "x" } }, as: :json

      expect(response).to redirect_to(root_path)
      expect(page.reload.draft).to be(false)
    end
  end

  describe "PATCH publish" do
    let!(:page) { create(:page, game: game, draft: true) }

    it "publishes the page and redirects to its show screen" do
      sign_in(gm)

      patch publish_game_page_path(game, page)

      expect(page.reload.draft).to be(false)
      expect(response).to redirect_to(game_page_path(game, page))
      expect(flash[:notice]).to eq("Page published.")
    end

    it "denies a non-member" do
      sign_in(outsider)

      patch publish_game_page_path(game, page)

      expect(response).to redirect_to(root_path)
      expect(page.reload.draft).to be(true)
    end
  end
end
