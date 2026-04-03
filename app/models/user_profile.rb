# typed: true

class UserProfile < ApplicationRecord
  extend T::Sig

  belongs_to :user

  validates :display_name, length: { maximum: 100 }, allow_blank: true

  sig { returns(T::Boolean) }
  def display_name_set?
    display_name.present?
  end
end
