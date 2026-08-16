# typed: true
# frozen_string_literal: true

# Content templates are managed only by the GM — a template configures how new
# content of a type starts, so there is no player-facing surface. new? =>
# create? and edit? => update? via the base policy.
class ContentTemplatePolicy < ApplicationPolicy
  extend T::Sig

  # May create, edit, or delete this game's templates. Answered by "is the GM"
  # (gm? is the private implementation); every write predicate delegates to it
  # so a rule change is a one-line edit.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  sig { returns(T::Boolean) }
  def create?
    manage?
  end

  sig { returns(T::Boolean) }
  def update?
    manage?
  end

  sig { returns(T::Boolean) }
  def destroy?
    manage?
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end
end
