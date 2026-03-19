FactoryBot.define do
  factory :game_member do
    game
    user
    role { "player" }
    status { "active" }

    trait :game_master do
      role { "game_master" }
    end

    trait :removed do
      status { "removed" }
    end

    trait :banned do
      status { "banned" }
    end
  end
end
