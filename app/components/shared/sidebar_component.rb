# typed: true

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

  sig { params(game: Game).returns(T::Boolean) }
  def game_master_in?(game)
    user = @current_user
    return false if user.equal?(nil)

    game.member_for(T.cast(user.__getobj__, User))&.game_master? || false
  end
end
