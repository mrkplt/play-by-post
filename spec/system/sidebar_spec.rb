require "rails_helper"

RSpec.describe "Sidebar", type: :feature do
  let(:user) { create(:user, :with_profile) }

  describe "when not logged in" do
    it "does not render the sidebar" do
      visit root_path

      expect(page).not_to have_css("aside.sidebar")
    end

    it "does not show user section" do
      visit root_path

      expect(page).not_to have_css(".sidebar-user")
    end
  end

  describe "when logged in" do
    before { sign_in_as(user) }

    it "renders the sidebar" do
      visit root_path

      expect(page).to have_css("aside.sidebar")
    end

    it "shows the Play by Post brand link" do
      visit root_path

      within "aside.sidebar" do
        expect(page).to have_link("Play by Post", href: root_path)
      end
    end

    it "shows the My Games nav link" do
      visit root_path

      within "aside.sidebar" do
        expect(page).to have_link("My Games", href: root_path)
      end
    end

    it "shows the user's display name" do
      visit root_path

      within "aside.sidebar" do
        expect(page).to have_text(user.user_profile.display_name)
      end
    end

    it "shows a sign out link" do
      visit root_path

      within "aside.sidebar" do
        expect(page).to have_link("Sign out")
      end
    end

    it "shows a profile settings link" do
      visit root_path

      within "aside.sidebar" do
        expect(page).to have_link(href: profile_path)
      end
    end

    describe "game list" do
      let(:game_one) { create(:game, name: "Dragon Campaign") }
      let(:game_two) { create(:game, name: "Space Opera") }

      before do
        create(:game_member, user: user, game: game_one)
        create(:game_member, user: user, game: game_two)
        create(:scene, game: game_one, updated_at: 2.days.ago)
        create(:scene, game: game_two, updated_at: 1.hour.ago)
      end

      it "lists the user's games" do
        visit root_path

        within "aside.sidebar" do
          expect(page).to have_link("Dragon Campaign")
          expect(page).to have_link("Space Opera")
        end
      end

      it "orders games by most recent scene activity" do
        visit root_path

        within "aside.sidebar nav" do
          links = page.all("a.sidebar-link").map(&:text).map(&:strip).reject(&:empty?)
          space_index = links.index { |t| t.include?("Space Opera") }
          dragon_index = links.index { |t| t.include?("Dragon Campaign") }
          expect(space_index).to be < dragon_index
        end
      end

      it "does not list games where the user is removed" do
        removed_game = create(:game, name: "Old Adventure")
        create(:game_member, :removed, user: user, game: removed_game)

        visit root_path

        within "aside.sidebar" do
          expect(page).not_to have_link("Old Adventure")
        end
      end

      it "shows a crown icon for GM games" do
        gm_game = create(:game, name: "GM Game")
        create(:game_member, :game_master, user: user, game: gm_game)

        visit root_path

        within "aside.sidebar" do
          gm_link = find("a.sidebar-link", text: /GM Game/)
          expect(gm_link).to have_css("svg")
        end
      end
    end
  end
end
