require "rails_helper"

# The avatar library on the profile screen. It reuses the same shared library
# component + cropper the character portraits do (covered thoroughly in
# character_portraits_spec), so this proves the shared UI works on the profile
# route too — render, set-current, and a full cropper upload — on both viewports.
RSpec.describe "User avatars", type: :feature do
  let(:user) { create(:user, :with_profile) }
  let(:avatar_fixture) { Rails.root.join("spec/fixtures/files/test_image.png") }

  def attach_avatar(image, filename)
    image.file.attach(
      io: File.open(avatar_fixture), filename: filename, content_type: "image/png"
    )
    image
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "on #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "shows the avatar section with the add trigger" do
        sign_in_as(user)
        visit profile_path

        within("[data-testid='image-library']") do
          # The section title renders through SectionLabelComponent, which
          # CSS-uppercases it, so Capybara reads the transformed text.
          expect(page).to have_text("AVATAR")
          expect(page).to have_text("No avatar yet.")
        end
        expect(page).to have_css("[data-testid='add-image']")
      end

      it "previews a clicked thumbnail immediately, then persists it on Save" do
        attach_avatar(create(:user_image, :current, user: user), "one.png")
        second = attach_avatar(create(:user_image, user: user), "two.png")

        sign_in_as(user)
        visit profile_path

        thumbs = all("[data-testid='library-item'] img")
        second_thumb = thumbs.find { |img| img["data-image-select-id-param"] == second.id.to_s }
        expected_src = second_thumb["data-image-select-display-url-param"]

        # Client-side only: the large preview swaps to the clicked thumbnail
        # and Save becomes usable before anything is persisted.
        second_thumb.click
        expect(page).to have_css("[data-testid='current-image'][src='#{expected_src}']")
        expect(second.reload.current?).to be(false)

        find("[data-testid='save-image-selection']").click

        expect(page).to have_text("Image updated.")
        expect(second.reload.current?).to be(true)
      end

      it "uploads a cropped avatar through the cropper" do
        sign_in_as(user)
        visit profile_path

        click_on "Add avatar"
        find("input[type='file']", visible: true).attach_file(avatar_fixture)

        expect(page).to have_css("[data-testid='crop-save']:not([disabled])", wait: 5)
        find("[data-testid='crop-save']").execute_script("this.click()")

        expect(page).to have_css("[data-testid='current-image']", wait: 10)
        expect(user.user_images.reload.count).to eq(1)
        expect(user.current_avatar).to be_present
      end
    end
  end
end
