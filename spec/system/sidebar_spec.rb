require "rails_helper"

# The global nav drawer (opened by the hamburger). Replaces the old persistent
# sidebar. The drawer markup is always present in the DOM (slid off-screen via
# CSS transform), so these assertions use visible: :all rather than opening it.
RSpec.describe "Nav drawer", type: :feature do
  let(:user) { create(:user, :with_profile) }

  describe "when not logged in" do
    it "does not render the drawer" do
      visit root_path
      expect(page).not_to have_css("aside.nav-drawer", visible: :all)
    end
  end

  describe "when logged in" do
    before { sign_in_as(user) }

    it "renders the drawer" do
      visit root_path
      expect(page).to have_css("aside.nav-drawer", visible: :all)
    end

    it "shows the user's display name in the profile chip" do
      visit root_path
      within("aside.nav-drawer", visible: :all) do
        expect(page).to have_text(user.user_profile.display_name)
      end
    end

    it "does not duplicate the profile link with a View Profile label" do
      # Fizzy #128: the chip and the footer both linked to the profile page;
      # the chip's redundant "View Profile" label is dropped.
      visit root_path
      within("aside.nav-drawer", visible: :all) do
        expect(page).not_to have_text("View Profile")
      end
    end

    it "shows Account Settings and Sign Out" do
      visit root_path
      within("aside.nav-drawer", visible: :all) do
        expect(page).to have_link("Account Settings", href: profile_path, visible: :all)
        expect(page).to have_link("Sign Out", visible: :all)
      end
    end

    describe "game list" do
      let(:game_one) { create(:game, name: "Dragon Campaign") }
      let(:game_two) { create(:game, name: "Space Opera") }

      before do
        create(:game_member, user: user, game: game_one)
        create(:game_member, user: user, game: game_two)
      end

      it "lists the user's games" do
        visit root_path
        within("aside.nav-drawer", visible: :all) do
          expect(page).to have_link("Dragon Campaign", visible: :all)
          expect(page).to have_link("Space Opera", visible: :all)
        end
      end

      it "lists former (removed) games too, with a moon indicator" do
        removed_game = create(:game, name: "Old Adventure")
        create(:game_member, :removed, user: user, game: removed_game)

        visit root_path
        within("aside.nav-drawer", visible: :all) do
          expect(page).to have_link("Old Adventure", visible: :all)
        end
      end

      it "never lists banned games" do
        banned_game = create(:game, name: "Forbidden")
        create(:game_member, :banned, user: user, game: banned_game)

        visit root_path
        within("aside.nav-drawer", visible: :all) do
          expect(page).not_to have_link("Forbidden", visible: :all)
        end
      end

      it "shows a crown icon for GM games" do
        gm_game = create(:game, name: "GM Game")
        create(:game_member, :game_master, user: user, game: gm_game)

        visit root_path
        within("aside.nav-drawer", visible: :all) do
          gm_link = find("a", text: /GM Game/, visible: :all)
          expect(gm_link).to have_css("svg", visible: :all)
        end
      end
    end
  end
end
