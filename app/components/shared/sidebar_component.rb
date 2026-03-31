# typed: true

class Shared::SidebarComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: T.nilable(User)).void }
  def initialize(current_user: nil)
    @current_user = current_user ? UserPresenter.new(current_user) : nil
  end

  sig { returns(T::Boolean) }
  def signed_in?
    @current_user.present?
  end
end
