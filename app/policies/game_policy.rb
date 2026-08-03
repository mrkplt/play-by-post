# typed: true
# frozen_string_literal: true

class GamePolicy < ApplicationPolicy
  extend T::Sig

  # Anyone who can see the game (GM, active, or removed member).
  sig { returns(T::Boolean) }
  def show?
    viewable?
  end

  # Any authenticated user may create a game (they become its GM).
  # new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    true
  end

  # Editing the game and its preference toggles is GM-only. edit? => update?.
  sig { returns(T::Boolean) }
  def update?
    gm?
  end

  # The player-management screen is visible to any game member; GM-only sections
  # within it are gated separately in the view.
  sig { returns(T::Boolean) }
  def manage_players?
    viewable?
  end

  # Requesting an export requires being able to see the game.
  sig { returns(T::Boolean) }
  def export?
    viewable?
  end

  # Write access to the game: the GM or an active member (mirrors the write
  # guard shared by post/character/scene creation).
  sig { returns(T::Boolean) }
  def write_access?
    membership = record.member_for(user)
    (membership&.game_master? || membership&.active?) || false
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
