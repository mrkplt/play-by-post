# typed: strict

class Shared::SidebarComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: T.nilable(User)).void }
  def initialize(current_user: nil)
    @current_user = T.let(current_user ? UserPresenter.new(current_user) : nil, T.nilable(UserPresenter))
  end

  sig { returns(T::Boolean) }
  def signed_in?
    !@current_user.equal?(nil)
  end

  # Whether the viewer may administer this game — the sidebar's crown. Asks
  # GamePolicy rather than the membership row directly, so this crown cannot
  # diverge from every other capability check when the rule granularizes.
  sig { params(game: Game).returns(T::Boolean) }
  def can_manage?(game)
    user = @current_user
    return false if user.equal?(nil)

    GamePolicy.new(T.cast(user.__getobj__, User), game).manage?
  end
end
