# typed: true
# frozen_string_literal: true

class CharacterPolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a sheet: game access plus the hidden-sheet gate.
  sig { returns(T::Boolean) }
  def show?
    access_game? && visible?
  end

  # Creating: any writer (GM or active member). new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    write_member?
  end

  # Editing: a writer who also owns the sheet (or is GM). edit? => update?.
  sig { returns(T::Boolean) }
  def update?
    write_member? && editable?
  end

  # Archiving/restoring a character is a roster-management action. archive?
  # and restore? both delegate to it, so when the rule granularizes (e.g. GM
  # status splitting from a delegated roster manager) this is the one line
  # that changes.
  sig { returns(T::Boolean) }
  def manage_roster?
    gm?
  end

  sig { returns(T::Boolean) }
  def archive?
    manage_roster?
  end

  sig { returns(T::Boolean) }
  def restore?
    manage_roster?
  end

  # The hidden-sheet gate on its own — a hidden sheet is visible only to its
  # owner or the GM. Used by the controller to render the "sheet is hidden"
  # redirect distinctly from a plain no-access redirect.
  sig { returns(T::Boolean) }
  def visible?
    !record.hidden? || editable?
  end

  # Field-level authorization: only the GM assigns a sheet's owner (user_id).
  # A player's sheet is always their own. `hidden` is intentionally writable by
  # any owner — players may hide their own sheet (REQUIREMENTS).
  #
  # This is the deliberate exception to "gm? has exactly one caller": reassigning
  # a sheet's owner and managing the roster are two different game functions that
  # happen to share a rule today. Routing this through manage_roster? would tie
  # them together, so granularizing one would silently move the other.
  sig { returns(T::Boolean) }
  def assign_owner?
    gm?
  end

  sig { returns(T::Array[Symbol]) }
  def permitted_attributes
    %i[name content hidden]
  end

  # Character visibility depends on the game (GM status + the sheets_hidden
  # toggle), so this scope is game-anchored: pass the Game as `scope`. Callers
  # chain .active / .archived on the result; `where` clauses compose regardless
  # of order. Instantiated directly (Pundit's escape hatch) rather than via
  # policy_scope, since the rule can't be derived from a bare relation.
  class Scope < ApplicationPolicy::Scope
    extend T::Sig

    sig { returns(T.untyped) }
    def resolve
      scope.characters.visible_to(user, scope)
    end
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def editable?
    record.editable_by?(user, record.game)
  end

  sig { returns(T::Boolean) }
  def access_game?
    record.game.viewable_by?(user)
  end

  # GM or active member — the write gate (mirrors require_active_member!).
  sig { returns(T::Boolean) }
  def write_member?
    membership = record.game.member_for(user)
    (membership&.game_master? || membership&.active?) || false
  end
end
