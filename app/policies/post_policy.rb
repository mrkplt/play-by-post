# typed: true
# frozen_string_literal: true

class PostPolicy < ApplicationPolicy
  extend T::Sig

  # Editing a post: owner, within the edit window (Post#editable_by?).
  # edit? => update? via base.
  sig { returns(T::Boolean) }
  def update?
    record.editable_by?(user)
  end

  # Posting into a scene: a participant (or GM) who is also an active member.
  sig { returns(T::Boolean) }
  def create?
    participate? && write_member?
  end

  # Marking a post read requires being able to take part in the scene.
  sig { returns(T::Boolean) }
  def mark_read?
    participate?
  end

  # Scene-level access shared by every post action: a participant or the GM.
  sig { returns(T::Boolean) }
  def participate?
    scene.participant?(user) || game.game_master?(user)
  end

  private

  sig { returns(Scene) }
  def scene
    record.scene
  end

  sig { returns(Game) }
  def game
    T.must(scene.game)
  end

  # Active member — the write gate. A GM is an active member; keyed on active
  # membership rather than the game_master role so a removed/banned member never
  # writes even if they hold the GM role.
  sig { returns(T::Boolean) }
  def write_member?
    game.active_member?(user)
  end
end
