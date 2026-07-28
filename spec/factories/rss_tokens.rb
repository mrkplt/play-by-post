FactoryBot.define do
  factory :rss_token do
    user
    token { SecureRandom.hex(32) }
  end
end
