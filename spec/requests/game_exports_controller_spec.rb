require "rails_helper"

RSpec.describe GameExportsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "POST /games/:game_id/export" do
    context "as active player" do
      before { sign_in(player) }

      it "creates an export request and enqueues the job" do
        expect {
          post game_export_path(game)
        }.to change(GameExportRequest, :count).by(1)
          .and have_enqueued_job(ExportJob)

        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to match(/export requested/i)
      end

      it "blocks a second request within 24 hours" do
        create(:game_export_request, :recent, user: player, game: game)

        expect {
          post game_export_path(game)
        }.not_to change(GameExportRequest, :count)

        expect(response).to redirect_to(game_path(game))
        expect(flash[:alert]).to match(/24 hours/i)
      end

      it "allows a request after the rate-limit window expires" do
        create(:game_export_request, :old, user: player, game: game)

        expect {
          post game_export_path(game)
        }.to change(GameExportRequest, :count).by(1)
      end
    end

    context "as GM" do
      before { sign_in(gm) }

      it "creates an export request" do
        expect {
          post game_export_path(game)
        }.to change(GameExportRequest, :count).by(1)
          .and have_enqueued_job(ExportJob)
      end
    end

    context "as removed member" do
      let(:removed) { create(:user, :with_profile) }

      before do
        create(:game_member, :removed, game: game, user: removed)
        sign_in(removed)
      end

      it "creates an export request" do
        expect {
          post game_export_path(game)
        }.to change(GameExportRequest, :count).by(1)
      end
    end

    context "as banned member" do
      let(:banned) { create(:user, :with_profile) }

      before do
        create(:game_member, :banned, game: game, user: banned)
        sign_in(banned)
      end

      it "redirects with an error" do
        post game_export_path(game)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "as non-member" do
      let(:outsider) { create(:user, :with_profile) }

      before { sign_in(outsider) }

      it "redirects with an error" do
        post game_export_path(game)
        expect(response).to redirect_to(root_path)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post game_export_path(game)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
