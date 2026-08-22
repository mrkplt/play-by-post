FactoryBot.define do
  factory :encrypted_value do
    # A key is person-owned — the owner is always a User (see EncryptedValue).
    association :owner, factory: :user
    value_type { "openrouter_key" }
    association :public_key

    trait :sealed do
      sealed_value { { wrapped_key: "wk", iv: "iv", ciphertext: "ct" }.to_json }
    end
  end
end
