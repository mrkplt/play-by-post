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

  sig { params(current_user: User, active_game_id: T.nilable(Integer)).void }
  def initialize(current_user:, active_game_id: nil)
    @user = T.let(UserPresenter.new(current_user), UserPresenter)
    @active_game_id = active_game_id
  end

  sig { returns(String) }
  def display_name
    @user.display_name_or_email
  end

  sig { returns(T::Array[GameMember]) }
  def memberships
    @user.drawer_memberships
  end

  sig { params(member: GameMember).returns(T::Boolean) }
  def active?(member)
    !@active_game_id.nil? && member.game_id == @active_game_id
  end

  # Which status glyph a game row shows: :crown (viewer is GM), :moon (former /
  # removed — dormant but browsable), or :plain (ordinary player game).
  sig { params(member: GameMember).returns(Symbol) }
  def status_icon(member)
    return :crown if member.game_master?
    return :moon if member.removed?

    :plain
  end

  sig { params(member: GameMember).returns(String) }
  def row_classes(member)
    base = "flex items-center gap-2.5 px-[18px] py-2.5 cursor-pointer no-underline"
    active?(member) ? "#{base} bg-sidebar-bg" : base
  end

  sig { params(member: GameMember).returns(String) }
  def game_name(member)
    T.must(member.game).name
  end

  sig { params(member: GameMember).returns(String) }
  def name_classes(member)
    base = "text-[13px] truncate"
    active?(member) ? "#{base} text-white font-bold" : "#{base} text-sidebar-text"
  end
end
