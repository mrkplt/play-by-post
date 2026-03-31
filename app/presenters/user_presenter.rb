# typed: true

class UserPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def display_name_or_email
    display_name || email.split("@").first
  end
end
