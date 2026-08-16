# typed: true
# frozen_string_literal: true

class PageVersionPolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a page version requires access to the game — version history follows
  # game access. But a draft page snapshots versions on every autosave, so a
  # version of a still-unpublished page is visible only to a manager (the GM);
  # otherwise a player could read draft content through the version endpoint,
  # bypassing the draft gate on the page itself.
  sig { returns(T::Boolean) }
  def show?
    page = record.page
    return PagePolicy.new(user, page).manage? if page.draft?

    GamePolicy.new(user, page.game).view?
  end
end
