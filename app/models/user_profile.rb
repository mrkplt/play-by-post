# typed: true

class UserProfile < ApplicationRecord
  extend T::Sig

  belongs_to :user

  validates :display_name, length: { maximum: 100 }, allow_blank: true

  sig { returns(T::Boolean) }
  def display_name_set?
    display_name.present?
  end

  # Assigns and persists a new display name in one call, so
  # ProfilesController#update only has to ask "did it save," not carry the two
  # separate statements that made up the assignment.
  sig { params(new_display_name: T.untyped).returns(T::Boolean) }
  def update_display_name(new_display_name)
    self.display_name = new_display_name
    save
  end
end
