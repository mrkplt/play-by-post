require "rails_helper"

RSpec.describe "Game Files", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "file list visibility" do
    let!(:game_file) do
      gf = create(:game_file, game: game, filename: "rules.pdf")
      gf.file.attach(io: StringIO.new("test"), filename: "rules.pdf", content_type: "application/pdf")
      gf
    end

    it "non-GM member can see the file list page" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_text("rules.pdf")
    end

    it "non-GM member cannot see upload form or delete button" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).not_to have_text("Upload File")
      expect(page).not_to have_button("Delete")
    end

    it "GM can see upload form and delete button" do
      sign_in_as(gm)
      visit game_game_files_path(game)

      expect(page).to have_text("Upload File")
      expect(page).to have_button("Delete")
    end
  end

  describe "banned user access" do
    it "banned user cannot access the files page" do
      banned_user = create(:user, :with_profile)
      create(:game_member, :banned, game: game, user: banned_user)

      sign_in_as(banned_user)
      visit game_game_files_path(game)

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("You do not have access")
    end
  end

  describe "game view file list" do
    it "shows files on the game page" do
      gf = create(:game_file, game: game, filename: "map.png")
      gf.file.attach(io: StringIO.new("test"), filename: "map.png", content_type: "image/png")

      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_text("map.png")
    end

    it "shows Manage Files link for GM only" do
      sign_in_as(gm)
      visit game_path(game)
      expect(page).to have_link("Manage Files")

      sign_in_as(player)
      visit game_path(game)
      expect(page).not_to have_link("Manage Files")
    end
  end
end
