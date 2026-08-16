require "rails_helper"

RSpec.describe ContentTemplatesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET index" do
    it "lists the game's templates for the GM" do
      create(:content_template, game: game, content_type: "page", body: "page seed")
      sign_in(gm)
      get game_content_templates_path(game)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Page")
    end

    it "denies a player" do
      sign_in(player)
      get game_content_templates_path(game)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST create" do
    it "creates a template for the GM" do
      sign_in(gm)

      expect {
        post game_content_templates_path(game),
             params: { content_template: { content_type: "note", body: "note seed" } }
      }.to change(ContentTemplate, :count).by(1)

      expect(response).to redirect_to(game_content_templates_path(game))
      expect(game.content_templates.find_by(content_type: "note").body).to eq("note seed")
    end

    it "re-renders on validation failure (duplicate type)" do
      create(:content_template, game: game, content_type: "page")
      sign_in(gm)

      expect {
        post game_content_templates_path(game),
             params: { content_template: { content_type: "page", body: "dup" } }
      }.not_to change(ContentTemplate, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies a player" do
      sign_in(player)

      expect {
        post game_content_templates_path(game),
             params: { content_template: { content_type: "note", body: "x" } }
      }.not_to change(ContentTemplate, :count)
    end
  end

  describe "PATCH update" do
    let!(:template) { create(:content_template, game: game, content_type: "page", body: "old") }

    it "updates the template body for the GM" do
      sign_in(gm)

      patch game_content_template_path(game, template),
            params: { content_template: { content_type: "page", body: "new" } }

      expect(template.reload.body).to eq("new")
      expect(response).to redirect_to(game_content_templates_path(game))
    end
  end

  describe "DELETE destroy" do
    let!(:template) { create(:content_template, game: game) }

    it "deletes the template for the GM" do
      sign_in(gm)

      expect {
        delete game_content_template_path(game, template)
      }.to change(ContentTemplate, :count).by(-1)
      expect(response).to redirect_to(game_content_templates_path(game))
    end

    it "denies a player" do
      sign_in(player)

      expect {
        delete game_content_template_path(game, template)
      }.not_to change(ContentTemplate, :count)
    end
  end

  describe "GET new / edit" do
    it "renders the new form for the GM" do
      sign_in(gm)
      get new_game_content_template_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form for the GM" do
      template = create(:content_template, game: game)
      sign_in(gm)
      get edit_game_content_template_path(game, template)
      expect(response).to have_http_status(:ok)
    end
  end
end
