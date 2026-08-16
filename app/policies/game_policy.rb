# typed: true
# frozen_string_literal: true

class GamePolicy < ApplicationPolicy
  extend T::Sig

  # Anyone who can see the game (GM, active, or removed member). show? and
  # view? ask the same question; show? exists because Pundit's `authorize`
  # infers it from action_name, view? is the name callers outside that
  # inference should reach for.
  sig { returns(T::Boolean) }
  def show?
    view?
  end

  # Any authenticated user may create a game (they become its GM).
  # new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    true
  end

  # Editing the game and its preference toggles is a manage-game action.
  # edit? => update?.
  sig { returns(T::Boolean) }
  def update?
    manage?
  end

  # Deleting the game (soft-delete, then scheduled purge) is a manage-game
  # action.
  sig { returns(T::Boolean) }
  def destroy?
    manage?
  end

  # May view this game at all (GM, active, or removed member). The capability
  # name for what `policy(@game).show?` call sites are actually asking; the
  # controllers' require_game_access! guards ask it for their own distinct
  # message and are not replaced by it.
  sig { returns(T::Boolean) }
  def view?
    viewable?
  end

  # May administer this game: edit its settings, delete it, manage its pages/
  # links/roster/notebook. Currently answered by "is the GM" (gm? is the
  # private implementation), but the capability is the stable name — when GM
  # status splits from game ownership or grants permission levels, this is the
  # one line that changes.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  # The player-management screen is visible to any game member; the sections
  # within it that administer the roster are gated separately in the view.
  # Built on view?, not viewable? — a capability composes from the capability
  # below it, so the private role check has exactly one caller.
  sig { returns(T::Boolean) }
  def manage_players?
    view?
  end

  # Requesting an export requires being able to see the game.
  sig { returns(T::Boolean) }
  def export?
    view?
  end

  # Write access to the game: an active member (a GM is an active member;
  # mirrors the write guard shared by post/character/scene creation). Keyed on
  # active membership rather than the game_master role, so a removed/banned
  # member never writes even if they also hold the GM role — correctness no
  # longer rests on GM status being immutable (which multiple game masters would
  # break).
  sig { returns(T::Boolean) }
  def write_access?
    record.active_member?(user)
  end

  # RSS feed access (machine-auth, DataApplicationController): the GM or an
  # active member. Re-checked on every request so a removed/banned member's
  # feed dies immediately even while their token still exists. The GM branch of
  # write_access? is status-blind by role, which is safe only because a GM's
  # membership status cannot be changed (GameMembersController forbids it), so a
  # banned/removed GM is unreachable.
  sig { returns(T::Boolean) }
  def feed?
    write_access?
  end

  # Which scenes this user's export of the game includes: everything for the GM,
  # only participated scenes for a removed member, otherwise the normally-visible
  # set. Removed members export less than they can view (see REQUIREMENTS).
  sig { returns(Symbol) }
  def export_scene_selection
    membership = record.member_for(user)
    return :all if membership&.game_master?
    return :participating if membership&.removed?

    :visible
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def viewable?
    record.viewable_by?(user)
  end
end
