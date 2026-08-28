require "rails_helper"

RSpec.describe Shared::MemberRosterComponent, type: :component do
  let(:the_game) { create(:game) }
  # A real GamePresenter (the component's sig enforces the type at runtime); the
  # component builds real status-change routes through it, so its status_url logic
  # is exercised (not stubbed).
  let(:game) { GamePresenter.new(the_game) }

  # Real GameMemberPresenter rows (the component's sigs enforce the type at
  # runtime, so doubles are rejected). status: drives active?/removed?.
  def member(display_name:, status:)
    user = create(:user, :with_profile)
    user.user_profile.update!(display_name: display_name)
    GameMemberPresenter.new(create(:game_member, game: the_game, user: user, status: status))
  end

  it "shows the empty state when there are no members" do
    render_inline(described_class.new(game: game, members: []))
    expect(page).to have_text("No players yet.")
  end

  it "renders Remove and Ban (to the right status routes) for an active member, and no Reinstate" do
    member = member(display_name: "Ada", status: "active")
    render_inline(described_class.new(game: game, members: [ member ]))

    expect(page).to have_link("Remove", href: Rails.application.routes.url_helpers.game_player_management_game_member_path(the_game, member, status: "removed"))
    expect(page).to have_link("Ban", href: Rails.application.routes.url_helpers.game_player_management_game_member_path(the_game, member, status: "banned"))
    expect(page).to have_no_link("Reinstate")
  end

  it "renders only Reinstate (to the active route) for a removed member" do
    member = member(display_name: "Bo", status: "removed")
    render_inline(described_class.new(game: game, members: [ member ]))

    expect(page).to have_link("Reinstate", href: Rails.application.routes.url_helpers.game_player_management_game_member_path(the_game, member, status: "active"))
    expect(page).to have_no_link("Remove")
    expect(page).to have_no_link("Ban")
  end

  it "renders a row per member" do
    members = [ member(display_name: "Ada", status: "active"), member(display_name: "Bo", status: "removed") ]
    render_inline(described_class.new(game: game, members: members))
    expect(page).to have_text("Ada")
    expect(page).to have_text("Bo")
  end

  describe "#position" do
    it "is :last for the final member and :middle otherwise" do
      first = member(display_name: "Ada", status: "active")
      last = member(display_name: "Bo", status: "active")
      component = described_class.new(game: game, members: [ first, last ])
      expect(component.position(last)).to eq(:last)
      expect(component.position(first)).to eq(:middle)
    end
  end

  describe "#any?" do
    it "is true with members and false without" do
      expect(described_class.new(game: game, members: [ member(display_name: "A", status: "active") ]).any?).to be(true)
      expect(described_class.new(game: game, members: []).any?).to be(false)
    end
  end
end
