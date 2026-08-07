FactoryBot.define do
  factory :game_link do
    game
    sequence(:description) { |n| "Reference #{n}" }
    sequence(:url) { |n| "https://example.com/reference-#{n}" }
  end
end
