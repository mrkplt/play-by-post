FactoryBot.define do
  factory :encrypted_value do
    # Owner defaults to a User (a player's BYOK value); pass owner: explicitly
    # for a Game-owned (GM fallback) value.
    association :owner, factory: :user
    value_type { "openrouter_key" }
    association :public_key

    trait :for_game do
      association :owner, factory: :game
    end

    trait :sealed do
      sealed_value { { wrapped_key: "wk", iv: "iv", ciphertext: "ct" }.to_json }
    end
  end
end
