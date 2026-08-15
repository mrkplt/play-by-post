FactoryBot.define do
  factory :game do
    name { "Test Game" }
    description { "A test game" }
    sheets_hidden { false }
    # Explicit so build_stubbed games (which skip the before_validation that
    # assigns one) still yield a valid, unique slug when a URL helper calls
    # to_param. The sequence keeps it unique for the uniqueness validation.
    sequence(:slug) { |n| "test-game-#{n}" }
  end
end
