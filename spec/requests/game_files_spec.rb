require "rails_helper"

RSpec.describe GameFilesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = get game_game_files_path(game_id)
  end

  describe "GET /games/:game_id/game_files" do
    it "GM can access the file index" do
      sign_in(gm)
      get game_game_files_path(game)
      expect(response).to have_http_status(:ok)
    end

    # Asserting the message, not just the redirect: Pundit's own denial also
    # lands on root_path, so without this the spec passes even with
    # require_game_access! deleted entirely.
    it "is denied to a non-member" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)
      get game_game_files_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have access to this game.")
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

    it "shows the upload form to the GM" do
      sign_in(gm)
      get game_game_files_path(game)
      expect(response.body).to include("Upload File")
    end

    it "hides the upload form from a player" do
      sign_in(player)
      get game_game_files_path(game)
      expect(response.body).not_to include("Upload File")
    end

    it "renders the universal header nav affordances" do
      sign_in(player)
      get game_game_files_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Files")
    end

    it "orders files newest first" do
      sign_in(gm)
      older = create(:game_file, game: game, filename: "older.pdf", created_at: 2.days.ago)
      older.file.attach(io: StringIO.new("x"), filename: "older.pdf", content_type: "application/pdf")
      newer = create(:game_file, game: game, filename: "newer.pdf", created_at: 1.day.ago)
      newer.file.attach(io: StringIO.new("x"), filename: "newer.pdf", content_type: "application/pdf")

      get game_game_files_path(game)

      expect(response.body.index("newer.pdf")).to be < response.body.index("older.pdf")
    end
  end

  describe "POST /games/:game_id/game_files" do
    context "with no file provided" do
      it "redirects with alert" do
        sign_in(gm)
        post game_game_files_path(game), params: { game_file: { file: nil } }
        expect(response).to have_http_status(:ok)
        expect(flash[:alert]).to match(/select a file/i)
      end
    end

    context "with a valid file" do
      it "creates game file and re-renders the list in place" do
        sign_in(gm)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "test.pdf")
        expect {
          post game_game_files_path(game), params: { game_file: { file: uploaded } }
        }.to change(GameFile, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("game_files_list")
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

    context "with a file over the size limit" do
      it "re-renders the form with the size error shown" do
        sign_in(gm)
        oversized = Rack::Test::UploadedFile.new(
          StringIO.new("x" * (GameFile::MAX_SIZE + 1)), "application/pdf", original_filename: "big.pdf"
        )
        expect {
          post game_game_files_path(game), params: { game_file: { file: oversized } }
        }.not_to change(GameFile, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be less than 50MB")
      end
    end

    context "with a disallowed file type" do
      it "renders the validation error instead of failing silently" do
        sign_in(gm)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/zip", original_filename: "archive.zip")
        expect {
          post game_game_files_path(game), params: { game_file: { file: uploaded } }
        }.not_to change(GameFile, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be a PDF, Word doc, text, markdown, or image file")
      end
    end

    context "as player" do
      it "is redirected with alert" do
        sign_in(player)
        uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "test.pdf")
        post game_game_files_path(game), params: { game_file: { file: uploaded } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
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
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("game_files_list")
      expect(flash[:notice]).to match(/deleted/i)
    end

    it "player cannot delete a file" do
      sign_in(player)
      expect {
        delete game_game_file_path(game, game_file)
      }.not_to change(GameFile, :count)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    # The delete-own rule (Fizzy #18) makes deletion authorization
    # record-specific — a player may delete a file they uploaded but not one the
    # GM did — so the record is looked up before it is authorized, and a
    # nonexistent id 404s uniformly (matching GameLinksController, which has
    # always looked up first). Existence is not concealed behind the auth check.
    context "ordering: the record is looked up before it is authorized" do
      it "gives a non-GM the not-found outcome for a nonexistent file id" do
        sign_in(player)
        delete game_game_file_path(game, id: 0)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/could not be found/i)
      end

      it "gives a GM the not-found outcome for a nonexistent file id" do
        sign_in(gm)
        delete game_game_file_path(game, id: 0)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/could not be found/i)
      end
    end
  end

  # Fizzy #18: with player contributions enabled, an active player may upload
  # files and delete the ones they uploaded, but not the GM's, and nothing once
  # the GM turns the setting off.
  describe "player contributions" do
    def upload
      Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", original_filename: "player.pdf")
    end

    context "when enabled" do
      before { game.update!(player_contributions_enabled: true) }

      it "lets an active player upload a file, attributed to them" do
        sign_in(player)
        expect {
          post game_game_files_path(game), params: { game_file: { file: upload } }
        }.to change(GameFile, :count).by(1)
        expect(GameFile.last.created_by).to eq(player)
      end

      it "lets a player delete a file they uploaded" do
        own = create(:game_file, game: game, created_by: player)
        sign_in(player)
        expect {
          delete game_game_file_path(game, own)
        }.to change(GameFile, :count).by(-1)
      end

      it "does not let a player delete the GM's file" do
        gm_file = create(:game_file, game: game, created_by: gm)
        sign_in(player)
        expect {
          delete game_game_file_path(game, gm_file)
        }.not_to change(GameFile, :count)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when disabled" do
      it "denies a player uploading a file" do
        sign_in(player)
        expect {
          post game_game_files_path(game), params: { game_file: { file: upload } }
        }.not_to change(GameFile, :count)
      end

      it "denies a player deleting a file they uploaded while it was enabled" do
        own = create(:game_file, game: game, created_by: player)
        sign_in(player)
        expect {
          delete game_game_file_path(game, own)
        }.not_to change(GameFile, :count)
      end
    end
  end
end
