# typed: true
# frozen_string_literal: true

# Viewing a notebook entry version follows the notebook's read rule: the
# notebook is GM-only (unlike pages, which are member-readable), so a version is
# visible only to a game master in good standing. A banned (or removed) member
# never reads notes even if they still hold the game_master role — the same
# status-aware gate as NotebookEntryPolicy#gm?.
class NotebookEntryVersionPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def show?
    active_gm?
  end

  private

  # Game master AND currently active: role alone is status-blind, and a banned
  # game master must not read notes. Composed from two single-call predicates so
  # the symbolic verifier can encode each atom.
  sig { returns(T::Boolean) }
  def active_gm?
    game_master? && active?
  end

  sig { returns(T::Boolean) }
  def game_master?
    record.notebook_entry.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def active?
    record.notebook_entry.game.active_member?(user)
  end
end
