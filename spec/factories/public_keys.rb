FactoryBot.define do
  factory :public_key do
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
    public_key { "-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----" }
  end
end
