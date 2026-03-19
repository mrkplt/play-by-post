FactoryBot.define do
  factory :character do
    game
    user
    sequence(:name) { |n| "Character #{n}" }
    content { "Character sheet content" }
    active { true }
    hidden { false }

    trait :inactive do
      active { false }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
