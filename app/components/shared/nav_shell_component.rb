# typed: strict

class Shared::NavShellComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: User, active_game_id: T.nilable(Integer)).void }
  def initialize(current_user:, active_game_id: nil)
    @current_user = current_user
    @active_game_id = active_game_id
  end

  sig { returns(User) }
  attr_reader :current_user

  sig { returns(T.nilable(Integer)) }
  attr_reader :active_game_id
end
