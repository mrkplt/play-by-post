FactoryBot.define do
  factory :rss_token do
    user
    game { nil }
    token { SecureRandom.hex(32) }

    trait :for_game do
      game
    end
  end
end
