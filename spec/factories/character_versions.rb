FactoryBot.define do
  factory :character_version do
    character
    association :edited_by, factory: :user
    content { "Character sheet version content" }
  end
end
