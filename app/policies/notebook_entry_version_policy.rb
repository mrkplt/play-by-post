# typed: true
# frozen_string_literal: true

# Viewing a notebook entry version follows the notebook's read rule: the
# notebook is GM-only in every direction (unlike pages, which are member-
# readable), so a version is visible only to the game's GM. Mirrors
# NotebookEntryPolicy#manage?'s `record.game.game_master?(user)` gate.
class NotebookEntryVersionPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def show?
    gm?
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.notebook_entry.game.game_master?(user)
  end
end
