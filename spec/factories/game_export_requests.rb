FactoryBot.define do
  factory :game_export_request do
    user
    game

    trait :all_games do
      game { nil }
    end

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 25.hours.ago }
    end
  end
end
