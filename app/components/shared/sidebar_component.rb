# typed: true

class Shared::SidebarComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: T.nilable(User)).void }
  def initialize(current_user: nil)
    @user = T.let(current_user, T.nilable(User))
    @current_user = T.let(current_user ? UserPresenter.new(current_user) : nil, T.nilable(UserPresenter))
  end

  sig { returns(T::Boolean) }
  def signed_in?
    !@user.nil?
  end

  sig { params(game: Game).returns(T::Boolean) }
  def game_master_in?(game)
    return false if @user.nil?

    game.member_for(@user)&.game_master? || false
  end
end
