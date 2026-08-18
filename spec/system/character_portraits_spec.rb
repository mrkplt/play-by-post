require "rails_helper"

# The player-facing portrait library on the character screen, exercised on both
# viewports. The cropper's canvas→blob→upload path is JS-driven (Cropper.js +
# fetch); the deterministic parts — the section rendering, opening the cropper,
# and set-current / delete through the UI — are asserted here, and the upload is
# driven end to end via the file input.
RSpec.describe "Character portraits", type: :feature do
  let(:player) { create(:user, :with_profile) }
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game, user: player) }
  let(:portrait_fixture) { Rails.root.join("spec/fixtures/files/test_image.png") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  def attach_portrait(image, filename)
    image.file.attach(
      io: File.open(portrait_fixture), filename: filename, content_type: "image/png"
    )
    image
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "on #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "shows the empty state when the character has no portraits" do
        sign_in_as(player)
        visit game_character_path(game, character)

        within("[data-testid='image-library']") do
          expect(page).to have_text("No portraits yet.")
        end
        expect(page).to have_css("[data-testid='add-image']")
      end

      it "renders the current portrait and library thumbnails for the owner" do
        attach_portrait(create(:character_image, :current, character: character), "one.png")
        attach_portrait(create(:character_image, character: character), "two.png")

        sign_in_as(player)
        visit game_character_path(game, character)

        expect(page).to have_css("[data-testid='current-image']")
        expect(page).to have_css("[data-testid='library-item']", count: 2)
      end

      it "opens the cropper modal from the Add image button" do
        sign_in_as(player)
        visit game_character_path(game, character)

        # The modal (and its file input) start hidden; opening reveals them.
        expect(page).to have_no_field(type: "file", visible: true)
        click_on "Add portrait"
        expect(page).to have_field(type: "file", visible: true)
      end

      it "lets the owner switch the current portrait" do
        attach_portrait(create(:character_image, :current, character: character), "one.png")
        second = attach_portrait(create(:character_image, character: character), "two.png")

        sign_in_as(player)
        visit game_character_path(game, character)

        # Only the non-current image offers "Use"; clicking it makes it current.
        click_on "Use"

        expect(page).to have_text("Image updated.")
        expect(second.reload.current?).to be(true)
      end

      it "lets the owner delete a portrait" do
        attach_portrait(create(:character_image, character: character), "one.png")

        sign_in_as(player)
        visit game_character_path(game, character)

        accept_confirm do
          find("[data-testid='delete-image']").click
        end

        expect(page).to have_text("Image deleted.")
        expect(character.character_images.count).to eq(0)
      end
    end
  end

  it "does not show management controls to a non-owner (the GM)" do
    attach_portrait(create(:character_image, :current, character: character), "one.png")

    sign_in_as(gm)
    visit game_character_path(game, character)

    expect(page).to have_css("[data-testid='current-image']")
    expect(page).to have_no_css("[data-testid='add-image']")
    expect(page).to have_no_css("[data-testid='use-image']")
    expect(page).to have_no_css("[data-testid='delete-image']")
  end

  it "uploads a cropped portrait through the cropper" do
    sign_in_as(player)
    visit game_character_path(game, character)

    click_on "Add portrait"
    # The modal is open now, so its file input is visible and directly attachable.
    find("input[type='file']", visible: true).attach_file(portrait_fixture)

    # Cropper initialises on file load; the save button enables once it does.
    expect(page).to have_css("[data-testid='crop-save']:not([disabled])", wait: 5)
    # The Cropper canvas overlays the modal, so a plain click can be intercepted;
    # dispatch the click directly on the enabled save button.
    find("[data-testid='crop-save']").execute_script("this.click()")

    expect(page).to have_css("[data-testid='current-image']", wait: 10)
    expect(character.character_images.reload.count).to eq(1)
    expect(character.current_portrait).to be_present
  end
end
