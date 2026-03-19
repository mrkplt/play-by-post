class CharacterVersion < ApplicationRecord
  belongs_to :character
  belongs_to :edited_by, class_name: "User"
end
