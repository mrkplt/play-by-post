FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }

    trait :with_profile do
      after(:create) do |user|
        create(:user_profile, user: user, display_name: "User #{user.id}")
      end
    end
  end
end
