# typed: true
# frozen_string_literal: true

class PageVersionPolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a page version requires access to the game — version history follows
  # game access. Routed through GamePolicy#view? so the game-access rule has one
  # implementation.
  sig { returns(T::Boolean) }
  def show?
    GamePolicy.new(user, record.page.game).view?
  end
end
