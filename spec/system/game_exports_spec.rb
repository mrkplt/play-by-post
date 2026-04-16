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

  describe "game show page" do
    context "as an active player" do
      before { create(:game_member, game: game, user: user, role: "player", status: "active") }

      it "shows an enabled Export Game button" do
        visit game_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end

      it "clicking Export Game and confirming shows a success notice" do
        visit game_path(game)

        accept_confirm do
          click_button "Export Game"
        end

        expect(page).to have_text("Export requested — you'll receive an email shortly.")
      end

      it "shows a disabled Export Game button when rate limited" do
        create(:game_export_request, :recent, user: user, game: game)

        visit game_path(game)

        expect(page).to have_button("Export Game", disabled: true)
      end
    end

    context "as a GM" do
      before { create(:game_member, :game_master, game: game, user: user) }

      it "shows an enabled Export Game button" do
        visit game_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end
    end

    context "as a removed member" do
      before { create(:game_member, game: game, user: user, role: "player", status: "removed") }

      it "shows an enabled Export Game button" do
        visit game_path(game)

        expect(page).to have_button("Export Game")
        expect(page).not_to have_button("Export Game", disabled: true)
      end
    end

    context "as a banned member" do
      before { create(:game_member, game: game, user: user, role: "player", status: "banned") }

      it "redirects away from the game page" do
        visit game_path(game)

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

    it "clicking Export All Games and confirming shows a success notice" do
      visit profile_path

      accept_confirm do
        click_button "Export All Games"
      end

      expect(page).to have_text("Export requested — you'll receive an email shortly.")
    end

    it "shows a disabled Export All Games button when rate limited" do
      create(:game_export_request, :recent, :all_games, user: user)

      visit profile_path

      expect(page).to have_button("Export All Games", disabled: true)
    end
  end
end
