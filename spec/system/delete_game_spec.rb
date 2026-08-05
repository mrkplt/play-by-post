require "rails_helper"

RSpec.describe "Delete game", type: :feature do
  let(:gm) { create(:user, :with_profile) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    sign_in_as(gm)
  end

  # The confirm input is compared to the game's stored name to gate the
  # destructive submit. A name with surrounding whitespace must still be
  # confirmable — the input is trimmed, so the stored name must be too, or the
  # button can never enable (regression: asymmetric trim left it disabled).
  [ "Curse of Strahd", "  Padded Name  " ].each do |name|
    context "game named #{name.inspect}" do
      let(:game) { create(:game, name: name) }

      it "enables the delete button only after the game name is typed" do
        visit game_player_management_path(game)
        click_on "Delete Game"

        submit = find("button[data-game-delete-target='submit']")
        expect(submit).to be_disabled

        find("#delete-game-confirm").set(game.name.strip)

        expect(submit).not_to be_disabled
      end
    end
  end
end
