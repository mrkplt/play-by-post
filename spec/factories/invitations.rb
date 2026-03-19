FactoryBot.define do
  factory :invitation do
    game
    association :invited_by, factory: :user
    sequence(:email) { |n| "invite#{n}@example.com" }

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
