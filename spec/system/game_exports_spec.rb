require "rails_helper"

RSpec.describe "Game Exports", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before { sign_in_as(user) }

  describe "game settings page" do
    context "as an active player" do
      before { create(:game_member, game: game, user: user, role: "player", status: "active") }

      it "shows an enabled Export Game button" do
        visit game_player_management_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end

      it "clicking Export Game shows a success notice without a confirmation dialog" do
        visit game_player_management_path(game)

        click_button "Export Game"

        expect(page).to have_text("Export requested — you'll receive an email shortly.")
      end

      it "keeps the Export Game button enabled and shows a last-export notice when a receipt exists" do
        receipt = create(:game_export_request, user: user, game: game, succeeded_at: 2.hours.ago)
        receipt.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")

        visit game_player_management_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
        expect(page).to have_text(/Last export: .+ ago/)
      end
    end

    context "as a GM" do
      before { create(:game_member, :game_master, game: game, user: user) }

      it "shows an enabled Export Game button" do
        visit game_player_management_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end
    end

    context "as a removed member" do
      before { create(:game_member, game: game, user: user, role: "player", status: "removed") }

      it "shows an enabled Export Game button" do
        visit game_player_management_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end
    end

    context "as a banned member" do
      before { create(:game_member, game: game, user: user, role: "player", status: "banned") }

      it "redirects away from the settings page" do
        visit game_player_management_path(game)

        expect(page).to have_text("You do not have access to this game.")
      end
    end
  end

  describe "profile page" do
    it "shows an enabled Export All Games button" do
      visit profile_path

      expect(page).to have_button("Export All Games")
      expect(page).not_to have_button("Export All Games", disabled: true)
    end

    it "clicking Export All Games shows a success notice without a confirmation dialog" do
      visit profile_path

      click_button "Export All Games"

      expect(page).to have_text("Export requested — you'll receive an email shortly.")
    end

    it "keeps the Export All Games button enabled and shows a last-export notice when a receipt exists" do
      receipt = create(:game_export_request, :all_games, user: user, succeeded_at: 2.hours.ago)
      receipt.archive.attach(io: StringIO.new("zip"), filename: "all.zip", content_type: "application/zip")

      visit profile_path

      expect(page).to have_button("Export All Games")
      expect(page).not_to have_button("Export All Games", disabled: true)
      expect(page).to have_text(/Last export: .+ ago/)
    end
  end
end
