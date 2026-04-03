require "rails_helper"

RSpec.describe GameFilesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:game_id/game_files" do
    it "GM can access the file index" do
      sign_in(gm)
      get game_game_files_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player can access the file index" do
      sign_in(player)
      get game_game_files_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get game_game_files_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /games/:game_id/game_files" do
    context "with no file provided" do
      it "redirects with alert" do
        sign_in(gm)
        post game_game_files_path(game), params: { game_file: { file: nil } }
        expect(response).to redirect_to(game_game_files_path(game))
        expect(flash[:alert]).to match(/select a file/i)
      end
    end

    context "with a valid file" do
      it "creates game file and redirects" do
        sign_in(gm)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "test.pdf")
        expect {
          post game_game_files_path(game), params: { game_file: { file: uploaded } }
        }.to change(GameFile, :count).by(1)
        expect(response).to redirect_to(game_game_files_path(game))
        expect(flash[:notice]).to match(/uploaded/i)
      end
    end

    context "when save fails" do
      it "renders :index with unprocessable_content" do
        sign_in(gm)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "test.pdf")
        allow_any_instance_of(GameFile).to receive(:save).and_return(false)
        post game_game_files_path(game), params: { game_file: { file: uploaded } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as player" do
      it "is redirected with alert" do
        sign_in(player)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "test.pdf")
        post game_game_files_path(game), params: { game_file: { file: uploaded } }
        expect(response).to redirect_to(game_path(game))
        expect(flash[:alert]).to match(/only the gm/i)
      end
    end
  end

  describe "DELETE /games/:game_id/game_files/:id" do
    let!(:game_file) { create(:game_file, game: game) }

    it "GM can delete a file" do
      sign_in(gm)
      expect {
        delete game_game_file_path(game, game_file)
      }.to change(GameFile, :count).by(-1)
      expect(response).to redirect_to(game_game_files_path(game))
      expect(flash[:notice]).to match(/deleted/i)
    end

    it "player cannot delete a file" do
      sign_in(player)
      expect {
        delete game_game_file_path(game, game_file)
      }.not_to change(GameFile, :count)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end
  end
end
