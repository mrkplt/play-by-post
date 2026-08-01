require "rails_helper"

RSpec.describe Shared::NavDrawerComponent, type: :component do
  let(:user) { create(:user, email: "dana@example.com") }
  let(:gm_game) { create(:game, name: "Sunken Archive") }
  let(:player_game) { create(:game, name: "Ashwood") }
  let(:former_game) { create(:game, name: "Nightfall") }
  let(:banned_game) { create(:game, name: "Hidden") }

  before do
    create(:user_profile, user: user, display_name: "Dana")
    create(:game_member, game: gm_game, user: user, role: "game_master", status: "active")
    create(:game_member, game: player_game, user: user, role: "player", status: "active")
    create(:game_member, game: former_game, user: user, role: "player", status: "removed")
    create(:game_member, game: banned_game, user: user, role: "player", status: "banned")
  end

  def rendered(active_game_id: nil)
    render_inline(described_class.new(current_user: user, active_game_id: active_game_id))
    page
  end

  it "shows the display name and View Profile" do
    r = rendered
    expect(r).to have_text("Dana")
    expect(r).to have_text("View Profile")
  end

  it "lists the GM, player, and former games" do
    r = rendered
    expect(r).to have_text("Sunken Archive")
    expect(r).to have_text("Ashwood")
    expect(r).to have_text("Nightfall")
  end

  it "never lists a banned game" do
    expect(rendered).not_to have_text("Hidden")
  end

  it "highlights the active game row" do
    expect(rendered(active_game_id: player_game.id)).to have_css("a.bg-sidebar-bg", text: "Ashwood")
  end

  it "does not highlight non-active rows" do
    expect(rendered(active_game_id: player_game.id)).not_to have_css("a.bg-sidebar-bg", text: "Sunken Archive")
  end

  it "picks the crown icon for a GM game" do
    member = user.game_members.find_by(game: gm_game)
    expect(described_class.new(current_user: user).status_icon(member)).to eq(:crown)
  end

  it "picks the moon icon for a removed game" do
    member = user.game_members.find_by(game: former_game)
    expect(described_class.new(current_user: user).status_icon(member)).to eq(:moon)
  end

  it "picks the plain icon for an ordinary player game" do
    member = user.game_members.find_by(game: player_game)
    expect(described_class.new(current_user: user).status_icon(member)).to eq(:plain)
  end

  it "renders Account Settings and Sign Out in the footer" do
    r = rendered
    expect(r).to have_text("Account Settings")
    expect(r).to have_text("Sign Out")
  end

  it "marks a row active only for the matching game" do
    c = described_class.new(current_user: user, active_game_id: player_game.id)
    member = user.game_members.find_by(game: player_game)
    other = user.game_members.find_by(game: gm_game)
    expect(c.active?(member)).to be true
    expect(c.active?(other)).to be false
  end

  it "treats no active_game_id as no active row" do
    c = described_class.new(current_user: user)
    member = user.game_members.find_by(game: player_game)
    expect(c.active?(member)).to be false
  end

  it "highlights the active row's class string but not others" do
    c = described_class.new(current_user: user, active_game_id: player_game.id)
    active_member = user.game_members.find_by(game: player_game)
    idle_member = user.game_members.find_by(game: gm_game)
    expect(c.row_classes(active_member)).to include("bg-sidebar-bg")
    expect(c.row_classes(idle_member)).not_to include("bg-sidebar-bg")
  end

  it "exposes the game name" do
    c = described_class.new(current_user: user)
    member = user.game_members.find_by(game: gm_game)
    expect(c.game_name(member)).to eq("Sunken Archive")
  end

  it "emphasizes the active row's name and mutes others" do
    c = described_class.new(current_user: user, active_game_id: player_game.id)
    active_member = user.game_members.find_by(game: player_game)
    idle_member = user.game_members.find_by(game: gm_game)
    expect(c.name_classes(active_member)).to include("text-white").and include("font-bold")
    expect(c.name_classes(idle_member)).to include("text-sidebar-text")
    expect(c.name_classes(idle_member)).not_to include("font-bold")
  end

  it "excludes banned games from drawer_memberships" do
    names = UserPresenter.new(user).drawer_memberships.map { |m| m.game.name }
    expect(names).to contain_exactly("Sunken Archive", "Ashwood", "Nightfall")
  end
end
