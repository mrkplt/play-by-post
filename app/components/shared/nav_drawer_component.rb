# typed: strict

# The global navigation drawer opened by the hamburger (☰): a fixed profile
# chip at the top, a scrollable list of the player's games in the middle (each
# with a status icon — GM crown, former moon, or plain), and pinned Account
# Settings / Sign Out at the bottom.
#
# The three regions are laid out so only the games list scrolls (flex-1,
# overflow-y-auto, min-h-0) — the header and footer never push the drawer
# taller than its viewport.
class Shared::NavDrawerComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: UserPresenter, active_game_id: T.nilable(Integer)).void }
  def initialize(current_user:, active_game_id: nil)
    @user = T.let(current_user, UserPresenter)
    @active_game_id = active_game_id
  end

  sig { returns(String) }
  def display_name
    @user.display_name_or_email
  end

  # One presenter per game row. Each already knows its own name, whether it is
  # the active row, and which status glyph it carries — this component only
  # turns those answers into markup.
  sig { returns(T::Array[DrawerMembershipPresenter]) }
  def memberships
    @memberships ||= T.let(
      @user.drawer_memberships.map do |membership|
        DrawerMembershipPresenter.new(membership, active_game_id: @active_game_id)
      end,
      T.nilable(T::Array[DrawerMembershipPresenter])
    )
  end

  sig { params(member: DrawerMembershipPresenter).returns(String) }
  def row_classes(member)
    base = "flex items-center gap-2.5 px-[18px] py-2.5 cursor-pointer no-underline"
    member.active? ? "#{base} bg-sidebar-bg" : base
  end

  sig { params(member: DrawerMembershipPresenter).returns(String) }
  def name_classes(member)
    base = "text-[13px] truncate"
    member.active? ? "#{base} text-white font-bold" : "#{base} text-sidebar-text"
  end
end
