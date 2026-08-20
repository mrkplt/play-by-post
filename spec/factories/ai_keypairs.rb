FactoryBot.define do
  factory :ai_keypair do
    user
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
    public_key { "-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----" }
  end
end
