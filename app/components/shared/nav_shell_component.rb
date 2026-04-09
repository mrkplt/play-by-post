# typed: strict

class Shared::NavShellComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: User).void }
  def initialize(current_user:)
    @current_user = current_user
  end
end
