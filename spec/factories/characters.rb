FactoryBot.define do
  factory :character do
    game
    user
    sequence(:name) { |n| "Character #{n}" }
    content { "Character sheet content" }
    archived_at { nil }
    hidden { false }

    trait :archived do
      archived_at { Time.current }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
