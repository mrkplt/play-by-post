# typed: true

class CharacterVersion < ApplicationRecord
  extend T::Sig

  belongs_to :character
  belongs_to :edited_by, class_name: "User"
end
