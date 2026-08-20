FactoryBot.define do
  factory :ai_keypair do
    # Owner defaults to a User (a player's BYOK keypair); use the :for_game
    # trait for a game-level fallback keypair.
    association :owner, factory: :user
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
    public_key { "-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----" }

    trait :for_game do
      association :owner, factory: :game
    end
  end
end
