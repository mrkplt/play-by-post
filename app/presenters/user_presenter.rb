# typed: true

class UserPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def display_name_or_email
    @model.display_name || @model.email.split("@").first
  end
end
