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
