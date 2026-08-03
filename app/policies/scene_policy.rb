# typed: true
# frozen_string_literal: true

class ScenePolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a scene: game access plus the private-scene gate.
  sig { returns(T::Boolean) }
  def show?
    access_game? && visible?
  end

  # Only the GM creates scenes. new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    gm?
  end

  sig { returns(T::Boolean) }
  def resolve?
    gm?
  end

  # Editing a scene's participant roster is a GM action.
  sig { returns(T::Boolean) }
  def manage_participants?
    gm?
  end

  # Joining a scene requires write access (GM or active member). The private and
  # resolved preconditions are scene-state rules enforced (with their own
  # messages) at the controller.
  sig { returns(T::Boolean) }
  def join?
    write_member?
  end

  # Reply-by-email (SceneMailbox): only a participant may post by email.
  sig { returns(T::Boolean) }
  def reply_by_email?
    participant?
  end

  # The private-scene gate on its own: a private scene is visible only to the GM
  # or a participant. Public scenes are visible to any game member.
  sig { returns(T::Boolean) }
  def visible?
    gm? || !record.private? || participant?
  end

  sig { returns(T::Array[Symbol]) }
  def permitted_attributes
    %i[title private parent_scene_id]
  end

  # Scene visibility depends on the game (GM sees all; others see public scenes
  # plus their own private ones), so this scope is game-anchored: pass the Game
  # as `scope`. Instantiated directly per Pundit's escape hatch.
  class Scope < ApplicationPolicy::Scope
    extend T::Sig

    sig { returns(T.untyped) }
    def resolve
      scope.scenes.visible_to(user, scope)
    end
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def participant?
    record.participant?(user)
  end

  sig { returns(T::Boolean) }
  def access_game?
    record.game.viewable_by?(user)
  end

  sig { returns(T::Boolean) }
  def write_member?
    membership = record.game.member_for(user)
    (membership&.game_master? || membership&.active?) || false
  end
end
