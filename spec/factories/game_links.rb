FactoryBot.define do
  factory :game_link do
    game
    # created_by is NOT NULL (Fizzy #18); default to a fresh user so a bare
    # create(:game_link) is valid. Specs that care about ownership pass their own.
    created_by factory: %i[user]
    sequence(:description) { |n| "Reference #{n}" }
    sequence(:url) { |n| "https://example.com/reference-#{n}" }
  end
end
