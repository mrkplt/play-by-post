FactoryBot.define do
  factory :page do
    game
    sequence(:title) { |n| "Page #{n}" }
    body { "# Heading\n\nSome **markdown** body." }
  end
end
