FactoryBot.define do
  factory :user_profile do
    user
    sequence(:display_name) { |n| "Player #{n}" }
    last_login_at { Time.current }
  end
end
