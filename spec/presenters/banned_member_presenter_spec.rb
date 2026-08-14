require "rails_helper"

RSpec.describe BannedMemberPresenter do
  let(:user) { build_stubbed(:user) }
  let(:member) { build_stubbed(:game_member, user: user, status: "banned") }
  let(:game) { build_stubbed(:game) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(member, game: game, urls: urls) }

  describe "#display_name" do
    it "delegates to UserPresenter for the member's display name" do
      allow(user).to receive(:display_name).and_return("Bob")
      expect(presenter.display_name).to eq("Bob")
    end
  end

  describe "#unban_path" do
    it "resolves the game_player_management_game_member_path with the game and member" do
      allow(urls).to receive(:game_player_management_game_member_path).with(game, member).and_return("/games/1/player_management/members/2")
      expect(presenter.unban_path).to eq("/games/1/player_management/members/2")
    end
  end
end
