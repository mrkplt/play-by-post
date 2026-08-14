require "rails_helper"

RSpec.describe Shared::NavDrawerComponent, type: :component do
  let(:user) { build_stubbed(:user, email: "dana@example.com") }
  let(:user_presenter) { UserPresenter.new(user) }
  let(:gm_game) { build_stubbed(:game, name: "Sunken Archive") }
  let(:player_game) { build_stubbed(:game, name: "Ashwood") }
  let(:former_game) { build_stubbed(:game, name: "Nightfall") }

  let(:gm_member) { build_stubbed(:game_member, game: gm_game, user: user, role: "game_master", status: "active") }
  let(:player_member) { build_stubbed(:game_member, game: player_game, user: user, role: "player", status: "active") }
  let(:former_member) { build_stubbed(:game_member, game: former_game, user: user, role: "player", status: "removed") }

  # The component takes an already-built UserPresenter, and the drawer's only
  # read is #drawer_memberships. Banned games are excluded there, which
  # UserPresenter's own spec covers. Stub the presenter's methods rather than
  # the underlying user, since the presenter is what the component reads.
  before do
    allow(user_presenter).to receive(:display_name_or_email).and_return("Dana")
    allow(user_presenter).to receive(:drawer_memberships)
      .and_return([ gm_member, player_member, former_member ])
  end

  def rendered(active_game_id: nil)
    render_inline(described_class.new(current_user: user_presenter, active_game_id: active_game_id))
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
    member = gm_member
    expect(described_class.new(current_user: user_presenter).status_icon(member)).to eq(:crown)
  end

  it "picks the moon icon for a removed game" do
    member = former_member
    expect(described_class.new(current_user: user_presenter).status_icon(member)).to eq(:moon)
  end

  it "picks the plain icon for an ordinary player game" do
    member = player_member
    expect(described_class.new(current_user: user_presenter).status_icon(member)).to eq(:plain)
  end

  it "renders Account Settings and Sign Out in the footer" do
    r = rendered
    expect(r).to have_text("Account Settings")
    expect(r).to have_text("Sign Out")
  end

  it "renders a Send Feedback button wired to the feedback modal" do
    expect(rendered).to have_css("button[data-action='click->feedback#open']", text: "Send Feedback")
  end

  it "marks a row active only for the matching game" do
    c = described_class.new(current_user: user_presenter, active_game_id: player_game.id)
    member = player_member
    other = gm_member
    expect(c.active?(member)).to be true
    expect(c.active?(other)).to be false
  end

  it "treats no active_game_id as no active row" do
    c = described_class.new(current_user: user_presenter)
    member = player_member
    expect(c.active?(member)).to be false
  end

  it "highlights the active row's class string but not others" do
    c = described_class.new(current_user: user_presenter, active_game_id: player_game.id)
    active_member = player_member
    idle_member = gm_member
    expect(c.row_classes(active_member)).to include("bg-sidebar-bg")
    expect(c.row_classes(idle_member)).not_to include("bg-sidebar-bg")
  end

  it "exposes the game name" do
    c = described_class.new(current_user: user_presenter)
    member = gm_member
    expect(c.game_name(member)).to eq("Sunken Archive")
  end

  it "emphasizes the active row's name and mutes others" do
    c = described_class.new(current_user: user_presenter, active_game_id: player_game.id)
    active_member = player_member
    idle_member = gm_member
    expect(c.name_classes(active_member)).to include("text-white").and include("font-bold")
    expect(c.name_classes(idle_member)).to include("text-sidebar-text")
    expect(c.name_classes(idle_member)).not_to include("font-bold")
  end
end
