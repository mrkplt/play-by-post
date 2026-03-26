require "rails_helper"

RSpec.describe "Game Files", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "gallery grid display" do
    let!(:image_file) do
      gf = create(:game_file, game: game, filename: "map.png")
      gf.file.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")), filename: "map.png", content_type: "image/png")
      gf
    end

    let!(:text_file) do
      gf = create(:game_file, game: game, filename: "notes.txt")
      gf.file.attach(io: StringIO.new("some notes"), filename: "notes.txt", content_type: "text/plain")
      gf
    end

    it "displays files in a gallery grid instead of a table" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_css(".gallery-grid")
      expect(page).not_to have_css("table")
      expect(page).to have_css(".gallery-card", count: 2)
    end

    it "shows filename on each card with title attribute" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_css(".gallery-card__filename", text: "map.png")
      expect(page).to have_css(".gallery-card__filename[title='map.png']")
    end

    it "shows file-type placeholder for non-thumbnailable files" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_css(".gallery-card__placeholder", text: "TXT")
    end
  end

  describe "download button" do
    let!(:game_file) do
      gf = create(:game_file, game: game, filename: "notes.txt")
      gf.file.attach(io: StringIO.new("test content"), filename: "notes.txt", content_type: "text/plain")
      gf
    end

    it "each card has a download link" do
      sign_in_as(player)
      visit game_game_files_path(game)

      within ".gallery-card" do
        expect(page).to have_css("a.gallery-card__action[title='Download']")
      end
    end
  end

  describe "lightbox modal" do
    let!(:image_file) do
      gf = create(:game_file, game: game, filename: "map.png")
      gf.file.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")), filename: "map.png", content_type: "image/png")
      gf
    end

    it "opens lightbox when clicking a card" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_css(".lightbox[hidden]", visible: :all)
      find(".gallery-card").click
      expect(page).not_to have_css(".lightbox[hidden]", visible: :all)
      expect(page).to have_css("[data-lightbox-title]", text: "map.png")
    end

    it "closes lightbox when clicking close button" do
      sign_in_as(player)
      visit game_game_files_path(game)

      find(".gallery-card").click
      expect(page).not_to have_css(".lightbox[hidden]", visible: :all)
      find(".lightbox__close").click
      expect(page).to have_css(".lightbox[hidden]", visible: :all)
    end

    it "closes lightbox when pressing escape" do
      sign_in_as(player)
      visit game_game_files_path(game)

      find(".gallery-card").click
      expect(page).not_to have_css(".lightbox[hidden]", visible: :all)
      find("body").send_keys(:escape)
      expect(page).to have_css(".lightbox[hidden]", visible: :all)
    end

    it "lightbox has a download button" do
      sign_in_as(player)
      visit game_game_files_path(game)

      find(".gallery-card").click
      within ".lightbox" do
        expect(page).to have_link("Download")
      end
    end
  end

  describe "GM file management" do
    let!(:game_file) do
      gf = create(:game_file, game: game, filename: "notes.txt")
      gf.file.attach(io: StringIO.new("test content"), filename: "notes.txt", content_type: "text/plain")
      gf
    end

    it "GM can see upload form" do
      sign_in_as(gm)
      visit game_game_files_path(game)

      expect(page).to have_text("Upload File")
    end

    it "GM can see delete button on cards" do
      sign_in_as(gm)
      visit game_game_files_path(game)

      expect(page).to have_css(".gallery-card__action--delete")
    end

    it "non-GM cannot see upload form or delete button" do
      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).not_to have_text("Upload File")
      expect(page).not_to have_css(".gallery-card__action--delete")
    end
  end

  describe "file upload (GM)" do
    let(:fixture_file) { Rails.root.join("spec/fixtures/files/test_document.txt") }

    it "GM can upload a file via the form" do
      sign_in_as(gm)
      visit game_game_files_path(game)

      attach_file "game_file[file]", fixture_file
      click_on "Upload"

      expect(page).to have_text("File uploaded.")
      expect(page).to have_text("test_document.txt")
    end

    it "shows alert when submitting without selecting a file" do
      sign_in_as(gm)
      visit game_game_files_path(game)

      click_on "Upload"

      expect(page).to have_text("Please select a file to upload.")
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

    it "shows Manage Files link for GM" do
      sign_in_as(gm)
      visit game_path(game)
      expect(page).to have_link("Manage Files")
    end

    it "shows View Files link for non-GM member" do
      sign_in_as(player)
      visit game_path(game)
      expect(page).to have_link("View Files")
    end
  end
end
