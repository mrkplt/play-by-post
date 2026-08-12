FactoryBot.define do
  factory :rss_token do
    user
    game
    token { SecureRandom.hex(32) }
  end
end
