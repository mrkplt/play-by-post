class UserProfile < ApplicationRecord
  belongs_to :user

  validates :display_name, length: { maximum: 100 }, allow_blank: true

  def display_name_set?
    display_name.present?
  end
end
