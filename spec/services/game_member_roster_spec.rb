require "rails_helper"

RSpec.describe GameMemberRoster do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:active_player) { create(:user, :with_profile) }
  let(:removed_player) { create(:user, :with_profile) }
  let(:banned_player) { create(:user, :with_profile) }
  let(:other_game_player) { create(:user, :with_profile) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: active_player, status: "active")
    create(:game_member, game: game, user: removed_player, status: "removed")
    create(:game_member, :banned, game: game, user: banned_player)
    create(:game_member, game: create(:game), user: other_game_player)
  end

  subject(:rows) { described_class.new(game).rows }

  it "includes active and removed players" do
    expect(rows.map(&:id)).to include(
      game.game_members.find_by(user: active_player).id,
      game.game_members.find_by(user: removed_player).id
    )
  end

  it "excludes banned players" do
    banned_id = game.game_members.find_by(user: banned_player).id
    expect(rows.map(&:id)).not_to include(banned_id)
  end

  it "excludes the GM (players only)" do
    gm_id = game.game_members.find_by(user: gm).id
    expect(rows.map(&:id)).not_to include(gm_id)
  end

  it "excludes members of other games" do
    expect(rows.map { |r| r.display_name }).not_to include(other_game_player.display_name)
  end

  it "returns GameMemberPresenter rows" do
    expect(rows).to all(be_a(GameMemberPresenter))
  end

  it "pairs each member with that user's first active character name" do
    create(:character, game: game, user: active_player, name: "Aria", archived_at: nil)
    row = rows.find { |r| r.id == game.game_members.find_by(user: active_player).id }
    expect(row.character_name).to eq("Aria")
  end

  it "leaves character_name nil for a member with no active character" do
    row = rows.find { |r| r.id == game.game_members.find_by(user: removed_player).id }
    expect(row.character_name).to be_nil
  end
end
