require "rails_helper"

# Draftable::Controller's shared save/publish helpers are exercised through a
# real adopter (Pages::DraftsController). The spec is described as
# Draftable::Controller so mutant attributes these examples to the module
# subject — mutant keys test selection to the described constant, so a spec
# describing only the concrete controller would leave the module unmeasured.
RSpec.describe Draftable::Controller, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "#draftable_save" do
    let!(:page) { create(:page, game: game, title: "Draft", body: "old") }

    it "autosaves the submitted attributes as a draft and returns the record id" do
      sign_in(gm)

      patch save_draft_game_page_path(game, page),
            params: { page: { title: "New", body: "new body" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("id" => page.slug)

      page.reload
      expect(page.draft).to be(true)
      expect(page.title).to eq("New")
      expect(page.body).to eq("new body")
    end

    it "forces the draft flag on even when the request omits it" do
      sign_in(gm)
      page.update!(draft: false)

      patch save_draft_game_page_path(game, page),
            params: { page: { body: "x" } }, as: :json

      expect(page.reload.draft).to be(true)
    end

    it "returns the validation errors with a 422 when the update fails" do
      sign_in(gm)
      allow_any_instance_of(Page).to receive(:update).and_return(false)
      allow_any_instance_of(Page).to receive_message_chain(:errors, :full_messages).and_return([ "boom" ])

      patch save_draft_game_page_path(game, page),
            params: { page: { body: "x" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [ "boom" ])
    end

    it "denies a non-GM" do
      sign_in(player)

      expect {
        patch save_draft_game_page_path(game, page),
              params: { page: { body: "x" } }, as: :json
      }.not_to change { page.reload.attributes }
    end
  end

  describe "#draftable_publish" do
    let!(:page) { create(:page, game: game, draft: true) }

    it "publishes the draft, redirects to it, and flashes the notice" do
      sign_in(gm)

      patch publish_game_page_path(game, page)

      expect(page.reload.draft).to be(false)
      expect(response).to redirect_to(game_page_path(game, page))
      expect(flash[:notice]).to eq("Page published.")
    end

    it "denies a non-GM" do
      sign_in(player)

      expect {
        patch publish_game_page_path(game, page)
      }.not_to change { page.reload.draft }
    end
  end
end
